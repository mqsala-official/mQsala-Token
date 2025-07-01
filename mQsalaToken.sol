// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

/**
 * @title MQSLA Token (Upgradeable - BEP-20)
 * @notice Utility-only token powering the mQsala ecosystem.
 *
 * - Hard-capped supply:      1_000_000_000 MQSLA (18 decimals)
 * - Dynamic auto-burn:       burnBP (basis points) = 0 at deployment, adjustable <= 2_000 (20%)
 * - Transfer controls:       Disabled P2P transfers until `licenseObtained == true`
 * with whitelists + per-address restrictions.
 * - Upgradeability:          UUPS pattern. Upgrade auth via ADMIN_ROLE (later DAO Timelock).
 * - Security:                Pausable, ERC20Votes snapshots, ERC20Permit, storage gap.
 */

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/governance/utils/VotesUpgradeable.sol";

contract MQSLAToken is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    ERC20PermitUpgradeable,
    ERC20VotesUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 1e18;
    uint16  public burnBP;
    uint16  public constant MAX_BURN_BP = 2_000; // 20%

    bool    public licenseObtained;
    // uint256 public tgeTimestamp;

    mapping(address => bool) public transferWhitelist;
    mapping(address => bool) public restricted;

    event LicenseStatusChanged(bool status);
    event BurnRateChanged(uint16 newBP);
    event AddressRestriction(address indexed acct, bool restricted);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        address admin_
    ) public initializer {
        __ERC20_init(name_, symbol_);
        __ERC20Permit_init(name_);
        __ERC20Votes_init();
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(ADMIN_ROLE, admin_);
        _grantRole(MINTER_ROLE, admin_);
        _grantRole(BURNER_ROLE, admin_);

        burnBP = 0;
        licenseObtained = false;

        transferWhitelist[admin_] = true;
    }

    // ---------- Hooks and Overrides for OZ v5+ ----------

    // The _update function replaces _beforeTokenTransfer and _afterTokenTransfer in OZ v5.
    // It is called for transfers, mints, and burns.
    function _update(address from, address to, uint256 value)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
        whenNotPaused
    {
        // Re-entrancy protection: Checks-Effects-Interactions pattern
        if (from != address(0) && to != address(0)) { // Standard transfer checks
            require(!restricted[from] && !restricted[to], "MQSLA: sender or receiver restricted");

            if (!licenseObtained) {
                require(
                    transferWhitelist[from] || transferWhitelist[to],
                    "MQSLA: transfers locked pre-licence"
                );
            }
        }
        
        // Handle mint/burn specific whitelist/restriction bypass
        if (from == address(0)) { // Minting
            require(!restricted[to], "MQSLA: cannot mint to a restricted address");
        }
        if (to == address(0)) { // Burning
            require(!restricted[from], "MQSLA: cannot burn from a restricted address");
        }

        // Call the parent _update functions (from both ERC20 and ERC20Votes)
        super._update(from, to, value);
    }
    
    // Restrict delegation function to only when licenseObtained == true
    function _delegate(address delegator, address delegatee)
        internal
        override(VotesUpgradeable)
    {
        require(licenseObtained, "MQSLA: delegation locked pre-licence");
        super._delegate(delegator, delegatee);
    }

    // Required override for OZ v5 due to inheriting from both ERC20Permit and NoncesUpgradeable
    function nonces(address owner)
        public
        view
        override(ERC20PermitUpgradeable, NoncesUpgradeable)
        returns (uint256)
    {
        return super.nonces(owner);
    }

    // ---------- Admin Functions ----------
    function setBurnBP(uint16 bp) external onlyRole(ADMIN_ROLE) {
        require(bp <= MAX_BURN_BP, "MQSLA: burn too high");
        burnBP = bp;
        emit BurnRateChanged(bp);
    }

    function setLicenseObtained(bool status) external onlyRole(ADMIN_ROLE) {
        licenseObtained = status;
        emit LicenseStatusChanged(status);
    }

    function setWhitelist(address account, bool allow)
        external
        onlyRole(ADMIN_ROLE)
    {
        transferWhitelist[account] = allow;
    }

    function setRestricted(address account, bool isRes)
        external
        onlyRole(ADMIN_ROLE)
    {
        restricted[account] = isRes;
        emit AddressRestriction(account, isRes);
    }

    function pause() external onlyRole(ADMIN_ROLE) { _pause(); }
    function unpause() external onlyRole(ADMIN_ROLE) { _unpause(); }

    // ---------- Mint / Burn Functions ----------
    function mint(address to, uint256 amount)
        external
        onlyRole(MINTER_ROLE)
    {
        require(totalSupply() + amount <= MAX_SUPPLY, "MQSLA: cap");
        
        // Integrate burn logic directly and use ceil formula for auto-burn calculation
        uint256 burnAmt = (amount * burnBP + 10_000 - 1) / 10_000;
        uint256 net = amount - burnAmt;

        if (burnAmt > 0) {
            _mint(address(0), burnAmt); // Mint to address(0) for burning
        }
        _mint(to, net);
    }

    // 'burnFrom' from ERC20Burnable is already handled by the access control
    function burnFrom(address account, uint256 amount)
        public
        override
        onlyRole(BURNER_ROLE)
    {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    // ---------- UUPS Upgradeability ----------
    function _authorizeUpgrade(address) internal override onlyRole(ADMIN_ROLE) {}
    
    // Unused overrides from previous version, now handled by the single _update function.
    // function _afterTokenTransfer...
    // function _mint...
    // function _burn...

    uint256[44] private __gap;
}

