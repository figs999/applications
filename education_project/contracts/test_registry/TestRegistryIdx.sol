pragma solidity ^0.4.23;

import '../auth_os/core/Contract.sol';
import '../auth_os/interfaces/GetterInterface.sol';
import '../auth_os/lib/ArrayUtils.sol';

// COMMENTME
library TestRegistryIdx {
  
  using Contract for *;
  using SafeMath for uint;
  using ArrayUtils for bytes32[];

  bytes32 internal constant EXEC_PERMISSIONS = keccak256('script_exec_permissions');

  // Returns the storage location of a script execution address's permissions -
  function execPermissions(address _exec) internal pure returns (bytes32)
    { return keccak256(_exec, EXEC_PERMISSIONS); }

  function init() external view {
    Contract.initialize();

    Contract.storing();

    Contract.set(execPermissions(msg.sender)).to(true);

    Contract.commit();
  }

  /// STORAGE SEEDS ///

  // Tests registered

  function registeredTests(bytes32 execID) internal pure returns (bytes32 location) {
    location = keccak256(execID, 'registered test');
  }

  // Test Bases
  
  function testBase(bytes32 test, bytes32 execID) internal pure returns (bytes32 location) {
    location = keccak256(execID, keccak256('test base', test));
  }

  function testDescription(bytes32 test, bytes32 execID) internal pure returns (bytes32 location) {
    location = keccak256('description', testBase(test, execID));
  }

  function testVersions(bytes32 test, bytes32 execID) internal pure returns (bytes32 location) {
    location = keccak256('test versions', testBase(test, execID));
  }

  // Version Bases

  function versionBase(bytes32 test, address version, bytes32 execID) internal pure returns (bytes32 location) {
    location = keccak256('version base', keccak256(execID, keccak256(version, test))); 
  }

  function versionDescription(bytes32 test, address version, bytes32 execID) internal pure returns (bytes32 location) {
    location = keccak256('description', versionBase(test, version, execID));
  }

  function versionIndex(bytes32 test, address version, bytes32 execID) internal pure returns (bytes32 location) {
    location = keccak256('index', versionBase(test, version, execID));
  }
  
  function previousVersion(bytes32 test, address version, bytes32 execID) internal pure returns (bytes32 location) {
    location = keccak256('previous version', versionBase(test, version, execID));
  }

  // Completion Seeds

  // Storage location for a mapping that reflects the most recent version of the test that this user has passed.
  function testCompletion(address user, bytes32 test, bytes32 execID) internal pure returns (bytes32 location) {
    location = keccak256('test completion', keccak256(execID, keccak256(user, test))); 
  }

  // Stroage location for a mapping that reflects whether or not the user has passed this verision of the test.
  function versionCompletion(address user, bytes32 test, address version, bytes32 execID) internal pure 
  returns (bytes32 location) {
    location = keccak256('version completion', keccak256(execID, keccak256(user, keccak256(version, test))));
  }

  /// REGISTRY GETTERS ///

  function getRegisteredTests(address _storage, bytes32 execID) external view returns (bytes32[] memory) {
    GetterInterface target = GetterInterface(_storage);

    uint registered_length = uint(target.read(execID, registeredTests(execID)));

    bytes32[] memory arr_indices = new bytes32[](registered_length);

    for (uint i = 0; i < registered_length; i++) 
      arr_indices[i] = bytes32(32 * (i + 1) + uint(registeredTests(execID)));
      
    return target.readMulti(execID, arr_indices);  
  }

  // FIXME ---> Need to test
  function getTestDescription(address _storage, bytes32 execID, bytes32 test) external view returns (bytes memory description) {
    GetterInterface target = GetterInterface(_storage);
    
    uint description_length = uint(target.read(execID, testDescription(test, execID)));

    uint to_add;
    if (description_length % 32 > 0) 
      to_add = 1;

    bytes32[] memory arr_indices = new bytes32[]((description_length/32) + to_add);

    for (uint i = 0; i < description_length; i+=32) 
      arr_indices[i / 32] = bytes32(i + 32 + uint(testDescription(test, execID)));

    description = target.readMulti(execID, arr_indices).toBytes(description_length);
  }

  function getTestVersions(address _storage, bytes32 execID, bytes32 test) external view returns (address[] memory) {
    GetterInterface target = GetterInterface(_storage);

    uint num_versions = uint(target.read(execID, testVersions(test, execID)));

    bytes32[] memory arr_indices = new bytes32[](num_versions);
    for (uint i = 1; i <= num_versions; i++) 
      arr_indices[i - 1] = bytes32(32 * i + uint(testVersions(test, execID)));

    return target.readMulti(execID, arr_indices).toAddressArr();
  }

  function getVersionDescription(address _storage, bytes32 execID, bytes32 test, address version) external view 
  returns (bytes memory description) {
    GetterInterface target = GetterInterface(_storage);
    
    uint description_length = uint(target.read(execID, versionDescription(test, version, execID)));

    uint to_add;
    if (description_length % 32 > 0) 
      to_add = 1;

    bytes32[] memory arr_indices = new bytes32[]((description_length/32) + to_add);

    for (uint i = 0; i < description_length; i+=32) 
      arr_indices[i / 32] = bytes32(i + 32 + uint(versionDescription(test, version, execID)));

    description = target.readMulti(execID, arr_indices).toBytes(description_length);
  }

  function getVersionIndex(address _storage, bytes32 execID, bytes32 test, address version) external view returns (uint) {
    return uint(GetterInterface(_storage).read(execID, versionIndex(test, version, execID)));
  }

  function getPreviousVersion(address _storage, bytes32 execID, bytes32 test, address version) external view 
  returns (address) {
    return address(GetterInterface(_storage).read(execID, previousVersion(test, version, execID)));
  }

  /// Completion Getters ///

  function getTestCompletion(address _storage, bytes32 execID, address user, bytes32 test) external view 
  returns (uint) {
    return uint(GetterInterface(_storage).read(execID, testCompletion(user, test, execID)));
  }

  function getVersionCompletion(address _storage, bytes32 execID, address user, bytes32 test, address version) external view
  returns (bool) {
    return GetterInterface(_storage).read(execID, versionCompletion(user, test, version, execID)) == bytes32(1) ? true : false;
  }

}
