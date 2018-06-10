pragma solidity ^0.4.23;

import "../../auth-os/Contract.sol";
import "./features/ConfigureSale.sol";
import "./features/ManageSale.sol";

library SaleManager {

  using Contract for *;

  /// SALE ///

  // Storage location of crowdsale admin address
  function admin() internal pure returns (bytes32)
    { return keccak256('sale_admin'); }

  // Whether the crowdsale and token are configured, and the sale is ready to run
  function isConfigured() internal pure returns (bytes32)
    { return keccak256("sale_is_configured"); }

  // Whether or not the crowdsale is post-purchase
  function isFinished() internal pure returns (bytes32)
    { return keccak256("sale_is_completed"); }

  // Storage location of the crowdsale's start time
  function startTime() internal pure returns (bytes32)
    { return keccak256("sale_start_time"); }

  // Storage location of the amount of time the crowdsale will take, accounting for all tiers
  function totalDuration() internal pure returns (bytes32)
    { return keccak256("sale_total_duration"); }

  // Storage location of the amount of tokens sold in the crowdsale so far. Does not include reserved tokens
  function tokensSold() internal pure returns (bytes32)
    { return keccak256("sale_tokens_sold"); }

  // Storage location of the minimum amount of tokens allowed to be purchased
  function globalMinPurchaseAmt() internal pure returns (bytes32)
    { return keccak256("sale_min_purchase_amt"); }

  /// TIERS ///

  // Stores the number of tiers in the sale
  function saleTierList() internal pure returns (bytes32)
    { return keccak256("sale_tier_list"); }

  // Stores the name of the tier
  function tierName(uint _idx) internal pure returns (bytes32)
    { return keccak256(_idx, "name", saleTierList()); }

  // Stores the number of tokens that will be sold in the tier
  function tierCap(uint _idx) internal pure returns (bytes32)
    { return keccak256(_idx, "cap", saleTierList()); }

  // Stores the price of a token (1 * 10^decimals units), in wei
  function tierPrice(uint _idx) internal pure returns (bytes32)
    { return keccak256(_idx, "price", saleTierList()); }

  // Stores the duration of a tier
  function tierDuration(uint _idx) internal pure returns (bytes32)
    { return keccak256(_idx, "duration", saleTierList()); }

  // Whether or not the tier's duration is modifiable (before it has begin)
  function tierModifiable(uint _idx) internal pure returns (bytes32)
    { return keccak256(_idx, "mod_stat", saleTierList()); }

  // Returns the storage location of the tier's whitelist status
  function tierWhitelisted(uint _idx) internal pure returns (bytes32)
    { return keccak256(_idx, "wl_stat", saleTierList()); }

  // Storage location of the index of the current tier. If zero, no tier is currently active
  function currentTier() internal pure returns (bytes32)
    { return keccak256("sale_current_tier"); }

  // Storage location of the end time of the current tier. Purchase attempts beyond this time will update the current tier (if another is available)
  function currentEndsAt() internal pure returns (bytes32)
    { return keccak256("current_tier_ends_at"); }

  /// FUNDS ///

  // Storage location of amount of wei raised during the crowdsale, total
  function totalWeiRaised() internal pure returns (bytes32)
    { return keccak256("sale_tot_wei_raised"); }

  /// WHITELIST ///

  // Stores a tier's whitelist
  function tierWhitelist(uint _idx) internal pure returns (bytes32)
    { return keccak256(_idx, "tier_whitelists"); }

  // Stores a spender's maximum wei spend amount for a given whitelisted tier
  function whitelistMaxWei(uint _idx, address _spender) internal pure returns (bytes32)
    { return keccak256(_spender, "max_wei", tierWhitelist(_idx)); }

  // Stores a spender's minimum token purchase amount for a given whitelisted tier
  function whitelistMinTok(uint _idx, address _spender) internal pure returns (bytes32)
    { return keccak256(_spender, "min_tok", tierWhitelist(_idx)); }

  /// TOKEN ///

  // Storage location for token name
  function tokenName() internal pure returns (bytes32)
    { return keccak256("token_name"); }

  // Storage location for token ticker symbol
  function tokenSymbol() internal pure returns (bytes32)
    { return keccak256("token_symbol"); }

  // Storage location for token decimals
  function tokenDecimals() internal pure returns (bytes32)
    { return keccak256("token_decimals"); }

  // Storage location for token totalSupply
  function tokenTotalSupply() internal pure returns (bytes32)
    { return keccak256("token_total_supply"); }

  // Storage seed for user balances mapping
  bytes32 internal constant TOKEN_BALANCES = keccak256("token_balances");

  function balances(address _owner) internal pure returns (bytes32)
    { return keccak256(_owner, TOKEN_BALANCES); }

  // Whether or not the token is unlocked for transfers
  function tokensUnlocked() internal pure returns (bytes32)
    { return keccak256('sale_tokens_unlocked'); }

  /// RESERVED TOKENS ///

  /// Storage location for an array of addresses with some form of reserved tokens
  function reservedDestinations() internal pure returns (bytes32)
    { return keccak256("reserved_token_dest_list"); }

  // Storage seed for reserved token information for a given address
  // Maps an address for which tokens are reserved to a struct:
  // Reservation { uint destination_list_index; uint num_tokens; uint num_percent; uint percent_decimals; }
  // destination_list_index is the address's index in TOKEN_RESERVED_DESTINATIONS, plus 1. 0 means the address is not in the list
  bytes32 internal constant TOKEN_RESERVED_ADDR_INFO = keccak256("token_reserved_addr_info");

  function reservations(address _destination) internal pure returns (bytes32)
    { return keccak256(_destination, TOKEN_RESERVED_ADDR_INFO); }

  /// CHECKS ///

  // Ensures that the sender is the admin address, and the sale is not initialized
  function onlyAdminAndNotInit() internal view {
    if (address(Contract.read(admin())) != Contract.sender())
      revert('sender is not admin');

    if (Contract.read(isConfigured()) != 0)
      revert('sale has already been configured');
  }

  // Ensures that the sender is the admin address, and the sale is not finalized
  function onlyAdminAndNotFinal() internal view {
    if (address(Contract.read(admin())) != Contract.sender())
      revert('sender is not admin');

    if (Contract.read(isFinished()) != 0)
      revert('sale has already been finalized');
  }

  // Ensure that the sender is the sale admin
  function onlyAdmin() internal view {
    if (address(Contract.read(admin())) != Contract.sender())
      revert('sender is not admin');
  }

  // Ensures both storage and events have been pushed to the buffer
  function emitAndStore() internal pure {
    if (Contract.emitted() == 0 || Contract.stored() == 0)
      revert('invalid state change');
  }

  // Ensures the pending state change will only store
  function onlyStores() internal pure {
    if (Contract.paid() != 0 || Contract.emitted() != 0)
      revert('expected only storage');

    if (Contract.stored() == 0)
      revert('expected storage');
  }

  /// CHECKS ///

  /*
  Allows the admin to update the global minimum number of tokens to purchase

  @param _new_minimum: The new minimum number of tokens that must be purchased
  */
  function updateGlobalMinContribution(uint _new_minimum) external view {
    // Begin execution - reads execution id and original sender address from storage
    Contract.authorize(msg.sender);
    // Check that the sender is the admin and the sale is not initialized
    Contract.checks(onlyAdminAndNotInit);
    // Execute function -
    ConfigureSale.updateGlobalMinContribution(_new_minimum);
    // Ensures state change will only affect storage and events -
    Contract.checks(emitAndStore);
    // Commit state changes to storage -
    Contract.commit();
  }

  /*
  Allows the admin to add additional crowdsale tiers before the start of the sale

  @param _tier_names: The name of each tier to add
  @param _tier_durations: The duration of each tier to add
  @param _tier_prices: The set purchase price for each tier
  @param _tier_caps: The maximum tokens to sell in each tier
  @param _tier_modifiable: Whether each tier's duration is modifiable or not
  @param _tier_whitelisted: Whether each tier incorporates a whitelist
  */
  function createCrowdsaleTiers(
    bytes32[] _tier_names, uint[] _tier_durations, uint[] _tier_prices, uint[] _tier_caps,
    bool[] _tier_modifiable, bool[] _tier_whitelisted
  ) external view {
    // Begin execution - reads execution id and original sender address from storage
    Contract.authorize(msg.sender);
    // Check that the sender is the admin and the sale is not initialized
    Contract.checks(onlyAdminAndNotInit);
    // Execute approval function -
    ConfigureSale.createCrowdsaleTiers(
      _tier_names, _tier_durations, _tier_prices,
      _tier_caps, _tier_modifiable, _tier_whitelisted
    );
    // Ensures state change will only affect storage and events -
    Contract.checks(emitAndStore);
    // Commit state changes to storage -
    Contract.commit();
  }

  /*
  Allows the admin to whitelist addresses for a tier which was setup to be whitelist-enabled -

  @param _tier_index: The index of the tier for which the whitelist will be updated
  @param _to_whitelist: An array of addresses that will be whitelisted
  @param _min_token_purchase: Each address' minimum purchase amount
  @param _max_wei_spend: Each address' maximum wei spend amount
  */
  function whitelistMultiForTier(
    uint _tier_index, address[] _to_whitelist, uint[] _min_token_purchase, uint[] _max_wei_spend
  ) external view {
    // Begin execution - reads execution id and original sender address from storage
    Contract.authorize(msg.sender);
    // Check that the sender is the sale admin -
    Contract.checks(onlyAdmin);
    // Execute approval function -
    ConfigureSale.whitelistMultiForTier(
      _tier_index, _to_whitelist, _min_token_purchase, _max_wei_spend
    );
    // Ensures state change will only affect storage -
    Contract.checks(onlyStores);
    // Commit state changes to storage -
    Contract.commit();
  }

  /*
  Allows the admin to update a tier's duration, provided it was marked as modifiable and has not started

  @param _tier_index: The index of the tier whose duration will be updated
  @param _new_duration: The new duration of the tier
  */
  function updateTierDuration(uint _tier_index, uint _new_duration) external view {
    // Begin execution - reads execution id and original sender address from storage
    Contract.authorize(msg.sender);
    // Check that the sender is the sale admin and that the sale is not finalized -
    Contract.checks(onlyAdminAndNotFinal);
    // Execute approval function -
    ConfigureSale.updateTierDuration(_tier_index, _new_duration);
    // Ensures state change will only affect storage -
    Contract.checks(onlyStores);
    // Commit state changes to storage -
    Contract.commit();
  }

  // Allows the admin to initialize a crowdsale, marking it configured
  function initializeCrowdsale() external view {
    // Begin execution - reads execution id and original sender address from storage
    Contract.authorize(msg.sender);
    // Check that the sender is the sale admin and the sale is not initialized -
    Contract.checks(onlyAdminAndNotInit);
    // Execute approval function -
    ManageSale.initializeCrowdsale();
    // Ensures state change will only affect storage and events -
    Contract.checks(emitAndStore);
    // Commit state changes to storage -
    Contract.commit();
  }

  // Allows the admin to finalize a crowdsale, marking it completed
  function finalizeCrowdsale() external view {
    // Begin execution - reads execution id and original sender address from storage
    Contract.authorize(msg.sender);
    // Check that the sender is the sale admin and that the sale is not finalized -
    Contract.checks(onlyAdminAndNotFinal);
    // Execute approval function -
    ManageSale.finalizeCrowdsale();
    // Ensures state change will only affect storage and events -
    Contract.checks(emitAndStore);
    // Commit state changes to storage -
    Contract.commit();
  }
}
