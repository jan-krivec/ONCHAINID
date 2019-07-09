pragma solidity ^0.5.0;

import "./IERC734.sol";

/**
 * @dev Implementation of the `IERC734` "KeyHolder" interface.
 */
contract ERC734 is IERC734 {
    uint256 public constant MANAGEMENT_KEY = 1;
    uint256 public constant ACTION_KEY = 2;
    uint256 public constant CLAIM_SIGNER_KEY = 3;
    uint256 public constant ENCRYPTION_KEY = 4;

    uint256 private executionNonce;

    struct Execution {
        address to;
        uint256 value;
        bytes data;
        bool approved;
        bool executed;
    }

    mapping (bytes32 => Key) private keys;
    mapping (uint256 => bytes32[]) private keysByPurpose;
    mapping (uint256 => Execution) private executions;

    event ExecutionFailed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);

    constructor() public {
        bytes32 _key = keccak256(abi.encodePacked(msg.sender));
        keys[_key].key = _key;
        keys[_key].purposes = [1];
        keys[_key].keyType = 1;
        keysByPurpose[1].push(_key);
        emit KeyAdded(_key, 1, 1);
    }

    /**
       * @notice Implementation of the getKey function from the ERC-734 standard
       *
       * @param _key The public key.  for non-hex and long keys, its the Keccak256 hash of the key
       *
       * @return Returns the full key data, if present in the identity.
       */

    function getKey(bytes32 _key)
    public
    view
    returns(uint256[] memory purposes, uint256 keyType, bytes32 key)
    {
        return (keys[_key].purposes, keys[_key].keyType, keys[_key].key);
    }

    /**
        * @notice gets all the keys with a specific purpose from an identity
        *
        * @param _purpose a uint256[] Array of the key types, like 1 = MANAGEMENT, 2 = ACTION, 3 = CLAIM, 4 = ENCRYPTION
        *
        * @return Returns an array of public key bytes32 hold by this identity and having the specified purpose
        */

    function getKeysByPurpose(uint256 _purpose)
    public
    view
    returns(bytes32[] memory _keys)
    {
        return keysByPurpose[_purpose];
    }

    /**
        * @notice implementation of the addKey function of the ERC-734 standard
        * Adds a _key to the identity. The _purpose specifies the purpose of key. Initially we propose four purposes:
        * 1: MANAGEMENT keys, which can manage the identity
        * 2: ACTION keys, which perform actions in this identities name (signing, logins, transactions, etc.)
        * 3: CLAIM signer keys, used to sign claims on other identities which need to be revokable.
        * 4: ENCRYPTION keys, used to encrypt data e.g. hold in claims.
        * MUST only be done by keys of purpose 1, or the identity itself.
        * If its the identity itself, the approval process will determine its approval.
        *
        * @param _key keccak256 representation of an ethereum address
        * @param _type type of key used, which would be a uint256 for different key types. e.g. 1 = ECDSA, 2 = RSA, etc.
        * @param _purpose a uint256[] Array of the key types, like 1 = MANAGEMENT, 2 = ACTION, 3 = CLAIM, 4 = ENCRYPTION
        *
        * @return Returns TRUE if the addition was successful and FALSE if not
        */

    function addKey(bytes32 _key, uint256 _purpose, uint256 _type)
    public
    returns (bool success)
    {
        if (msg.sender != address(this)) {
            require(keyHasPurpose(keccak256(abi.encodePacked(msg.sender)), 1), "Sender does not have management key"); // Sender has MANAGEMENT_KEY
        }

        if (keys[_key].key == _key) {
            require(!keyHasPurpose(_key, _purpose), "Key already has purpose");

            keys[_key].purposes.push(_purpose);
        } else {
            keys[_key].key = _key;
            keys[_key].purposes = [_purpose];
            keys[_key].keyType = _type;
        }

        keysByPurpose[_purpose].push(_key);

        emit KeyAdded(_key, _purpose, _type);

        return true;
    }

    function approve(uint256 _id, bool _approve)
    public
    returns (bool success)
    {
        require(keyHasPurpose(keccak256(abi.encodePacked(msg.sender)), 2), "Sender does not have action key");

        emit Approved(_id, _approve);

        if (_approve == true) {
            executions[_id].approved = true;

            (success,) = executions[_id].to.call.value(executions[_id].value)(abi.encode(executions[_id].data, 0));

            if (success) {
                executions[_id].executed = true;

                emit Executed(
                    _id,
                    executions[_id].to,
                    executions[_id].value,
                    executions[_id].data
                );

                return true;
            } else {
                emit ExecutionFailed(
                    _id,
                    executions[_id].to,
                    executions[_id].value,
                    executions[_id].data
                );

                return false;
            }
        } else {
            executions[_id].approved = false;
        }
        return true;
    }

    function execute(address _to, uint256 _value, bytes memory _data)
    public
    payable
    returns (uint256 executionId)
    {
        require(!executions[executionNonce].executed, "Already executed");
        executions[executionNonce].to = _to;
        executions[executionNonce].value = _value;
        executions[executionNonce].data = _data;

        emit ExecutionRequested(executionNonce, _to, _value, _data);

        if (keyHasPurpose(keccak256(abi.encodePacked(msg.sender)), 2)) {
            approve(executionNonce, true);
        }

        executionNonce++;
        return executionNonce-1;
    }

    function removeKey(bytes32 _key, uint256 _purpose)
    public
    returns (bool success)
    {
        Key memory key = keys[_key];
        require(key.key == _key, "No such key");

        if (msg.sender != address(this)) {
            require(keyHasPurpose(keccak256(abi.encodePacked(msg.sender)), 1), "Sender does not have management key"); // Sender has MANAGEMENT_KEY
        }

        uint purposeIndex = 0;
        while (key.purposes[purposeIndex] != _purpose) {
            purposeIndex++;
        }

        require(purposeIndex > 0, "Key dosn't have such purpose.");

        while (purposeIndex < key.purposes.length - 1) {
            key.purposes[purposeIndex] = key.purposes[purposeIndex+1];
            purposeIndex++;
        }

        bytes32[] memory keyList = keysByPurpose[_purpose];

        uint keyIndex = 0;

        while (keyList[keyIndex] != key.key) {
            keyIndex++;
        }

        while (keyIndex < keyList.length - 1) {
            keyList[keyIndex] = keyList[keyIndex+1];
            keyIndex++;
        }

        if (key.purposes.length == 0) {
            delete keys[_key];
        }

        emit KeyRemoved(keys[_key].key, _purpose, keys[_key].keyType);

        return true;
    }

    /**
    * @notice implementation of the changeKeysRequired from ERC-734 standard
    * Dilip TODO : complete the code for this function
    */
    function changeKeysRequired(uint256 purpose, uint256 number) external
    {
    }

    /**
    * @notice implementation of the getKeysRequired from ERC-734 standard
    * Dilip TODO : complete the code for this function
    */
    function getKeysRequired(uint256 purpose) external view returns(uint256)
    {
    }

    function keyHasPurpose(bytes32 _key, uint256 _purpose)
    public
    view
    returns(bool result)
    {
        Key memory key = keys[_key];
        if (key.key == 0) return false;

        for (uint keyPurposeIndex = 0; keyPurposeIndex < key.purposes.length; keyPurposeIndex++) {
            uint256 purpose = key.purposes[keyPurposeIndex];

            if (purpose == MANAGEMENT_KEY || purpose == _purpose) return true;
        }

        return false;
    }
}