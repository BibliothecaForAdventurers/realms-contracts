# -----------------------------------
# ____MODULE_L06___COMBAT_LOGIC
#   Logic for combat between characters, troops, etc.
#
# MIT License
# -----------------------------------

%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_block_timestamp, get_caller_address, get_tx_info

from openzeppelin.upgrades.library import (
    Proxy_initializer,
    Proxy_only_admin,
    Proxy_set_implementation,
)

from contracts.settling_game.interfaces.IERC1155 import IERC1155
from contracts.settling_game.interfaces.IModules import (
    IModuleController,
    IL02Resources,
    IL04Calculator,
)
from contracts.settling_game.interfaces.IRealmsERC721 import IRealmsERC721
from contracts.settling_game.interfaces.IXoroshiro import IXoroshiro
from contracts.settling_game.library.library_combat import Combat
from contracts.settling_game.utils.game_structs import (
    RealmData,
    RealmCombatData,
    Troop,
    Squad,
    SquadStats,
    PackedSquad,
    Cost,
)
from contracts.settling_game.utils.general import unpack_data, transform_costs_to_token_ids_values
from contracts.settling_game.library.library_module import Module
from contracts.settling_game.utils.constants import (
    DAY,
    ModuleIds,
    ExternalContractIds,
)

# -----------------------------------
# EVENTS
# -----------------------------------

@event
func CombatStart_2(
    attacking_realm_id : Uint256,
    defending_realm_id : Uint256,
    attacking_squad : Squad,
    defending_squad : Squad,
):
end

@event
func CombatOutcome_2(
    attacking_realm_id : Uint256,
    defending_realm_id : Uint256,
    attacking_squad : Squad,
    defending_squad : Squad,
    outcome : felt,
):
end

@event
func CombatStep_2(
    attacking_realm_id : Uint256,
    defending_realm_id : Uint256,
    attacking_squad : Squad,
    defending_squad : Squad,
    attack_type : felt,
    hit_points : felt,
):
end

@event
func BuildTroops_2(
    squad : Squad, troop_ids_len : felt, troop_ids : felt*, realm_id : Uint256, slot : felt
):
end

# -----------------------------------
# STORAGE
# -----------------------------------

@storage_var
func xoroshiro_address() -> (address : felt):
end

@storage_var
func realm_combat_data(realm_id : Uint256) -> (combat_data : RealmCombatData):
end

@storage_var
func troop_cost(troop_id : felt) -> (cost : Cost):
end

# -----------------------------------
# CONSTS
# -----------------------------------

# a min delay between attacks on a Realm; it can't
# be attacked again during cooldown
const ATTACK_COOLDOWN_PERIOD = DAY  # 1 day unit

# sets the attack type when initiating combat
const COMBAT_TYPE_ATTACK_VS_DEFENSE = 1
const COMBAT_TYPE_WISDOM_VS_AGILITY = 2

# used to signal which side won the battle
const COMBAT_OUTCOME_ATTACKER_WINS = 1
const COMBAT_OUTCOME_DEFENDER_WINS = 2

# used when adding or removing squads to Realms
const ATTACKING_SQUAD_SLOT = 1
const DEFENDING_SQUAD_SLOT = 2

# when defending, how many population does it take
# to inflict a single hit point on the attacker
const POPULATION_PER_HIT_POINT = 50
# upper limit (inclusive) of how many hit points
# can a defense wall inflict on the attacker
const MAX_WALL_DEFENSE_HIT_POINTS = 5

# -----------------------------------
# CONSTRUCTOR
# -----------------------------------

#@notice Module initializer
#@param address_of_controller: Controller/arbiter address
#@param xoroshiro_addr: Pseudorandomizer address
#@proxy_admin: Proxy admin address
@external
func initializer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address_of_controller : felt, xoroshiro_addr : felt, proxy_admin : felt
):
    MODULE_initializer(address_of_controller)
    xoroshiro_address.write(xoroshiro_addr)
    Proxy_initializer(proxy_admin)
    return ()
end

#@notice Set new proxy implementation
#@dev Can only be set by the arbiter
#@param new_implementation: New implementation contract address
@external
func upgrade{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    new_implementation : felt
):
    Proxy_only_admin()
    Proxy_set_implementation(new_implementation)
    return ()
end

# TODO: write documentation

# -----------------------------------
# EXTERNAL
# -----------------------------------

#@notice Build squad from troops in realm
#@param troop_ids_len: Size of troop ids
#@param troop_ids: List of troop ids to build
#@param realm_id: Staked realm token id
#@param slot: Troop slot
@external
func build_squad_from_troops_in_realm{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(troop_ids_len : felt, troop_ids : felt*, realm_id : Uint256, slot : felt):
    alloc_locals

    let (caller) = get_caller_address()
    let (controller) = Module.get_controller_address()

    Module.erc721_owner_check(realm_id, ExternalContractIds.S_Realms)

    # # get the Cost for every Troop to build
    # let (troop_costs : Cost*) = alloc()
    # load_troop_costs(troop_ids_len, troop_ids, 0, troop_costs)

    # # transform costs into tokens
    # let (token_ids : Uint256*) = alloc()
    # let (token_values : Uint256*) = alloc()
    # let (token_len : felt) = transform_costs_to_token_ids_values(
    #     troop_ids_len, troop_costs, token_ids, token_values
    # )

    # # pay for the squad
    # let (resource_address) = IModuleController.get_external_contract_address(
    #     controller, ExternalContractIds.Resources
    # )
    # IERC1155.burnBatch(resource_address, caller, token_len, token_ids, token_len, token_values)

    # assemble the squad, store it in a Realm
    let (realm_combat_data : RealmCombatData) = get_realm_combat_data(realm_id)
    if slot == ATTACKING_SQUAD_SLOT:
        let current_squad : Squad = COMBAT.unpack_squad(realm_combat_data.attacking_squad)
    else:
        let current_squad : Squad = COMBAT.unpack_squad(realm_combat_data.defending_squad)
    end
    let (squad) = COMBAT.add_troops_to_squad(current_squad, troop_ids_len, troop_ids)
    update_squad_in_realm(squad, realm_id, slot)

    BuildTroops_2.emit(squad, troop_ids_len, troop_ids, realm_id, slot)

    return ()
end

#@notice Initiate combat
#@param attacking_realm_id: Attacking realm token id
#@param defending_realm_id: Defending realm token id
#@param attack_type: Attack type
#@return combat_outcome: Combat outcome
@external
func initiate_combat{range_check_ptr, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*}(
    attacking_realm_id : Uint256, defending_realm_id : Uint256, attack_type : felt
) -> (combat_outcome : felt):
    alloc_locals

    with_attr error_message("L06Combat: Cannot initiate combat"):
        Module.erc721_owner_check(attacking_realm_id, ExternalContractIds.StakedRealms)
        let (can_attack) = realm_can_be_attacked(attacking_realm_id, defending_realm_id)
        assert can_attack = TRUE
    end

    let (attacking_realm_data : RealmCombatData) = get_realm_combat_data(attacking_realm_id)
    let (defending_realm_data : RealmCombatData) = get_realm_combat_data(defending_realm_id)

    let (attacker : Squad) = Combat.unpack_squad(attacking_realm_data.attacking_squad)
    let (defender : Squad) = Combat.unpack_squad(defending_realm_data.defending_squad)

    # EMIT FIRST
    CombatStart_2.emit(attacking_realm_id, defending_realm_id, attacker, defender)

    let (attacker_breached_wall : Squad) = inflict_wall_defense(attacker, defending_realm_id)

    let (attacker_end, defender_end, combat_outcome) = run_combat_loop(
        attacking_realm_id, defending_realm_id, attacker_breached_wall, defender, attack_type
    )

    let (new_attacker : PackedSquad) = COMBAT.pack_squad(attacker_end)
    let (new_defender : PackedSquad) = COMBAT.pack_squad(defender_end)

    let new_attacking_realm_data = RealmCombatData(
        attacking_squad=new_attacker,
        defending_squad=attacking_realm_data.defending_squad,
        last_attacked_at=attacking_realm_data.last_attacked_at,
    )
    set_realm_combat_data(attacking_realm_id, new_attacking_realm_data)

    let (now) = get_block_timestamp()
    let new_defending_realm_data = RealmCombatData(
        attacking_squad=defending_realm_data.attacking_squad,
        defending_squad=new_defender,
        last_attacked_at=now,
    )
    set_realm_combat_data(defending_realm_id, new_defending_realm_data)

    let (attacker_after_combat : Squad) = COMBAT.unpack_squad(new_attacker)
    let (defender_after_combat : Squad) = COMBAT.unpack_squad(new_defender)

    # # pillaging only if attacker wins
    if combat_outcome == COMBAT_OUTCOME_ATTACKER_WINS:
        let (controller) = Module.get_controller_address()
        let (resources_logic_address) = IModuleController.get_module_address(
            controller, ModuleIds.L02Resources
        )
        let (caller) = get_caller_address()
        IL02Resources.pillage_resources(resources_logic_address, defending_realm_id, caller)
        tempvar syscall_ptr = syscall_ptr
        tempvar range_check_ptr = range_check_ptr
        tempvar pedersen_ptr = pedersen_ptr
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar range_check_ptr = range_check_ptr
        tempvar pedersen_ptr = pedersen_ptr
    end

    CombatOutcome_2.emit(
        attacking_realm_id,
        defending_realm_id,
        attacker_after_combat,
        defender_after_combat,
        combat_outcome,
    )

    return (combat_outcome)
end

#@notice Remove one or more troops from a particular squad
#  troops to be removed are identified the their index in a Squad (0-based indexing)
#@param troop_idxs_len: Size of troop_idxs
#@param troop_idxs: List of indexes of troops to be removed
#@param realm_id: Realm token id
#@param slot: Troop slot
@external
func remove_troops_from_squad_in_realm{
    range_check_ptr, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*
}(troop_idxs_len : felt, troop_idxs : felt*, realm_id : Uint256, slot : felt):
    alloc_locals

    Module.erc721_owner_check(realm_id, ExternalContractIds.S_Realms)

    let (realm_combat_data : RealmCombatData) = get_realm_combat_data(realm_id)

    if slot == ATTACKING_SQUAD_SLOT:
        let (squad) = Combat.unpack_squad(realm_combat_data.attacking_squad)
    else:
        let (squad) = Combat.unpack_squad(realm_combat_data.defending_squad)
    end

    let (updated_squad) = Combat.remove_troops_from_squad(squad, troop_idxs_len, troop_idxs)
    update_squad_in_realm(updated_squad, realm_id, slot)

    return ()
end

# -----------------------------------
# INTERNAL
# -----------------------------------

#@notice Set realm combat data
#@param realm_id: Realm token id
#@param combat_data: Combat data object
func set_realm_combat_data{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    realm_id : Uint256, combat_data : RealmCombatData
):
    realm_combat_data.write(realm_id, combat_data)
    return ()
end

#@notice Inflicts damage to wall defense
#@param attacker: Attacking squad object
#@param defending_realm_id: Defender realm token id
#@return damaged: Damaged squad object
func inflict_wall_defense{range_check_ptr, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*}(
    attacker : Squad, defending_realm_id : Uint256
) -> (damaged : Squad):
    alloc_locals

    let (controller : felt) = Module.get_controller_address()
    let (calculator_addr : felt) = IModuleController.get_module_address(
        controller, ModuleIds.L04Calculator
    )
    # let (defending_population : felt) = IL04Calculator.calculate_population(
    #     calculator_addr, defending_realm_id
    # )

    let (q, _) = unsigned_div_rem(5, POPULATION_PER_HIT_POINT)
    let (is_in_range) = is_le(q, MAX_WALL_DEFENSE_HIT_POINTS)
    if is_in_range == TRUE:
        tempvar hit_points = q
    else:
        tempvar hit_points = MAX_WALL_DEFENSE_HIT_POINTS
    end

    let (damaged : Squad) = hit_squad(attacker, hit_points)
    return (damaged)
end

#@notice Run combat loop
#@param attacking_realm_id: Attacking realm token id
#@param defending_realm_id: Defending realm token id
#@param attacker: Attacking squad object
#@param defender: Defending squad object
#@attack_type: Attack type
#@return attacker: Attacking squad
#@return defender: Defending squad
#@return outcome: Combat outcome
func run_combat_loop{range_check_ptr, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*}(
    attacking_realm_id : Uint256,
    defending_realm_id : Uint256,
    attacker : Squad,
    defender : Squad,
    attack_type : felt,
) -> (attacker : Squad, defender : Squad, outcome : felt):
    alloc_locals

    let (step_defender) = attack(
        attacking_realm_id, defending_realm_id, attacker, defender, attack_type
    )

    let (defender_vitality) = Combat.compute_squad_vitality(step_defender)
    if defender_vitality == 0:
        # defender is defeated
        return (attacker, step_defender, COMBAT_OUTCOME_ATTACKER_WINS)
    end

    let (step_attacker) = attack(
        attacking_realm_id, defending_realm_id, step_defender, attacker, attack_type
    )
    let (attacker_vitality) = Combat.compute_squad_vitality(step_attacker)
    if attacker_vitality == 0:
        # attacker is defeated
        return (step_attacker, step_defender, COMBAT_OUTCOME_DEFENDER_WINS)
    end

    return run_combat_loop(
        attacking_realm_id, defending_realm_id, step_attacker, step_defender, attack_type
    )
end

#@notice Attack
#@param attacking_realm_id: Attacking realm token id
#@param defending_realm_id: Defending realm token id
#@param a: Attacking squad object
#@param d: Defending squad object
#@return d_after_attack: Defense squad after attack
func attack{range_check_ptr, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*}(
    attacking_realm_id : Uint256,
    defending_realm_id : Uint256,
    a : Squad,
    d : Squad,
    attack_type : felt,
) -> (d_after_attack : Squad):
    alloc_locals

    let (a_stats) = Combat.compute_squad_stats(a)
    let (d_stats) = Combat.compute_squad_stats(d)

    if attack_type == COMBAT_TYPE_ATTACK_VS_DEFENSE:
        # attacker attacks with attack against defense,
        # has attack-times dice rolls
        let (min_roll_to_hit) = compute_min_roll_to_hit(a_stats.attack, d_stats.defense)
        let (hit_points) = roll_attack_dice(a_stats.attack, min_roll_to_hit, 0)
        tempvar range_check_ptr = range_check_ptr
        tempvar syscall_ptr : felt* = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
    else:
        # COMBAT_TYPE_WISDOM_VS_AGILITY
        # attacker attacks with wisdom against agility,
        # has wisdom-times dice rolls
        let (min_roll_to_hit) = compute_min_roll_to_hit(a_stats.wisdom, d_stats.agility)
        let (hit_points) = roll_attack_dice(a_stats.wisdom, min_roll_to_hit, 0)
        tempvar range_check_ptr = range_check_ptr
        tempvar syscall_ptr : felt* = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
    end

    tempvar hit_points = hit_points
    tempvar syscall_ptr = syscall_ptr
    tempvar pedersen_ptr = pedersen_ptr

    let (d_after_attack) = hit_squad(d, hit_points)
    CombatStep_2.emit(
        attacking_realm_id, defending_realm_id, a, d_after_attack, attack_type, hit_points
    )
    return (d_after_attack)
end

#@notice Compute minimum roll needed to hit
#@dev min(math.ceil((a / d) * 7), 12
#@param a: Attack
#@param d: Defense
#@return min_roll: Minimum roll needed to hit
func compute_min_roll_to_hit{range_check_ptr}(a : felt, d : felt) -> (min_roll : felt):
    alloc_locals

    # in case there's no defense, any attack will succeed
    if d == 0:
        return (0)
    end

    let (q, r) = unsigned_div_rem(a * 7, d)
    local t
    if r == 0:
        t = q
    else:
        t = q + 1
    end

    # 12 sided die => max throw is 12
    let (is_within_range) = is_le(t, 12)
    if is_within_range == 0:
        return (12)
    end

    return (t)
end

#@notice Roll attack dice
#@param dice_count: Number of dice to roll
#@param hit_threshold: Lower bound to hit
#@param successful_hits_acc: ??
#@return successful_hits: Number of successful hits
func roll_attack_dice{range_check_ptr, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*}(
    dice_count : felt, hit_threshold : felt, successful_hits_acc
) -> (successful_hits : felt):
    # 12 sided dice, 1...12
    # only values >= hit threshold constitute a successful attack
    alloc_locals

    if dice_count == 0:
        return (successful_hits_acc)
    end

    let (xoroshiro_address_) = xoroshiro_address.read()
    let (rnd) = IXoroshiro.next(xoroshiro_address_)
    let (_, r) = unsigned_div_rem(rnd, 12)
    let (is_successful_hit) = is_le(hit_threshold, r)
    return roll_attack_dice(dice_count - 1, hit_threshold, successful_hits_acc + is_successful_hit)
end

#@notice Hit squad
#@param s: Squad object
#@param hits: Hits to deal out
#@return squad: Squad after hit
func hit_squad{range_check_ptr}(s : Squad, hits : felt) -> (squad : Squad):
    alloc_locals

    let (t1_1, remaining_hits) = hit_troop(s.t1_1, hits)
    let (t1_2, remaining_hits) = hit_troop(s.t1_2, remaining_hits)
    let (t1_3, remaining_hits) = hit_troop(s.t1_3, remaining_hits)
    let (t1_4, remaining_hits) = hit_troop(s.t1_4, remaining_hits)
    let (t1_5, remaining_hits) = hit_troop(s.t1_5, remaining_hits)
    let (t1_6, remaining_hits) = hit_troop(s.t1_6, remaining_hits)
    let (t1_7, remaining_hits) = hit_troop(s.t1_7, remaining_hits)
    let (t1_8, remaining_hits) = hit_troop(s.t1_8, remaining_hits)
    let (t1_9, remaining_hits) = hit_troop(s.t1_9, remaining_hits)
    let (t1_10, remaining_hits) = hit_troop(s.t1_10, remaining_hits)
    let (t1_11, remaining_hits) = hit_troop(s.t1_11, remaining_hits)
    let (t1_12, remaining_hits) = hit_troop(s.t1_12, remaining_hits)
    let (t1_13, remaining_hits) = hit_troop(s.t1_13, remaining_hits)
    let (t1_14, remaining_hits) = hit_troop(s.t1_14, remaining_hits)
    let (t1_15, remaining_hits) = hit_troop(s.t1_15, remaining_hits)
    let (t1_16, remaining_hits) = hit_troop(s.t1_16, remaining_hits)

    let (t2_1, remaining_hits) = hit_troop(s.t2_1, remaining_hits)
    let (t2_2, remaining_hits) = hit_troop(s.t2_2, remaining_hits)
    let (t2_3, remaining_hits) = hit_troop(s.t2_3, remaining_hits)
    let (t2_4, remaining_hits) = hit_troop(s.t2_4, remaining_hits)
    let (t2_5, remaining_hits) = hit_troop(s.t2_5, remaining_hits)
    let (t2_6, remaining_hits) = hit_troop(s.t2_6, remaining_hits)
    let (t2_7, remaining_hits) = hit_troop(s.t2_7, remaining_hits)
    let (t2_8, remaining_hits) = hit_troop(s.t2_8, remaining_hits)

    let (t3_1, _) = hit_troop(s.t3_1, remaining_hits)

    let s = Squad(
        t1_1=t1_1,
        t1_2=t1_2,
        t1_3=t1_3,
        t1_4=t1_4,
        t1_5=t1_5,
        t1_6=t1_6,
        t1_7=t1_7,
        t1_8=t1_8,
        t1_9=t1_9,
        t1_10=t1_10,
        t1_11=t1_11,
        t1_12=t1_12,
        t1_13=t1_13,
        t1_14=t1_14,
        t1_15=t1_15,
        t1_16=t1_16,
        t2_1=t2_1,
        t2_2=t2_2,
        t2_3=t2_3,
        t2_4=t2_4,
        t2_5=t2_5,
        t2_6=t2_6,
        t2_7=t2_7,
        t2_8=t2_8,
        t3_1=t3_1,
    )

    return (s)
end

#@notice Hit troop
#@param hit_troop: Target troop object
#@param hits: How many hits to deal
#@return hit_troop: Hit troop object
#@return remaining_hits: How many hits remain from the attack
func hit_troop{range_check_ptr}(t : Troop, hits : felt) -> (
    hit_troop : Troop, remaining_hits : felt
):
    if hits == 0:
        return (t, 0)
    end

    let (kills_troop) = is_le(t.vitality, hits)
    if kills_troop == 1:
        # t.vitality <= hits
        let ht = Troop(id=0, type=0, tier=0, agility=0, attack=0, defense=0, vitality=0, wisdom=0)
        let rem = hits - t.vitality
        return (ht, rem)
    else:
        # t.vitality > hits
        let ht = Troop(
            id=t.id,
            type=t.type,
            tier=t.tier,
            agility=t.agility,
            attack=t.attack,
            defense=t.defense,
            vitality=t.vitality - hits,
            wisdom=t.wisdom,
        )
        return (ht, 0)
    end
end

#@notice Load troop costs
#@param troop_ids_len: Size of troop_ids
#@param troop_ids: List of troop ids
#@param costs_idx: Costs index
#@param costs: List of costs
func load_troop_costs{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    troop_ids_len : felt, troop_ids : felt*, costs_idx : felt, costs : Cost*
):
    alloc_locals

    if troop_ids_len == 0:
        return ()
    end

    let (cost : Cost) = get_troop_cost([troop_ids])
    assert [costs + costs_idx] = cost

    return load_troop_costs(troop_ids_len - 1, troop_ids + 1, costs_idx + 1, costs)
end

#@notice Can be used to add, overwrite or remove a Squad from a Realm
#@param s: Squad object
#@param realm_id: Realm token id
#@param slot: Squad troop slot index
func update_squad_in_realm{range_check_ptr, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*}(
    s : Squad, realm_id : Uint256, slot : felt
):
    alloc_locals

    Module.erc721_owner_check(realm_id, ExternalContractIds.S_Realms)

    let (realm_combat_data : RealmCombatData) = get_realm_combat_data(realm_id)
    let (packed_squad : PackedSquad) = Combat.pack_squad(s)

    if slot == ATTACKING_SQUAD_SLOT:
        let new_realm_combat_data = RealmCombatData(
            attacking_squad=packed_squad,
            defending_squad=realm_combat_data.defending_squad,
            last_attacked_at=realm_combat_data.last_attacked_at,
        )
        set_realm_combat_data(realm_id, new_realm_combat_data)
        return ()
    else:
        let new_realm_combat_data = RealmCombatData(
            attacking_squad=realm_combat_data.attacking_squad,
            defending_squad=packed_squad,
            last_attacked_at=realm_combat_data.last_attacked_at,
        )
        set_realm_combat_data(realm_id, new_realm_combat_data)
        return ()
    end
end

# -----------------------------------
# GETTERS
# -----------------------------------

#@notice Get unpacked troops
#@param realm_id: Realm token id
#@return attacking_troops: Attacking squad object
#@return defending_troops: Defending squad object
@view
func view_troops{range_check_ptr, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*}(
    realm_id : Uint256
) -> (attacking_troops : Squad, defending_troops : Squad):
    alloc_locals

    let (realm_data : RealmCombatData) = get_realm_combat_data(realm_id)

    let (attacking_squad : Squad) = Combat.unpack_squad(realm_data.attacking_squad)
    let (defending_squad : Squad) = Combat.unpack_squad(realm_data.defending_squad)

    return (attacking_squad, defending_squad)
end

#@notice Get xoroshiro contract address
#@return xoroshiro_address: Xoroshiro contract address
@view
func get_xoroshiro{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    xoroshiro_address : felt
):
    let (xoroshiro) = xoroshiro_address.read()
    return (xoroshiro)
end

#@notice Get troop
#@param troop_id: Troop id
#@return t: Troop object
@view
func get_troop{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(troop_id : felt) -> (t : Troop):
    let (t : Troop) = Combat.get_troop_internal(troop_id)
    return (t)
end

#@notice Get realm combat data
#@param realm_id: Realm token id
#@return combat_data: Realm combat data object
@view
func get_realm_combat_data{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    realm_id : Uint256
) -> (combat_data : RealmCombatData):
    let (combat_data) = realm_combat_data.read(realm_id)
    return (combat_data)
end

#@notice Get troop cost by troop id
#@param troop_id: Troop id
#@return cost: Troop cost
@view
func get_troop_cost{range_check_ptr, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*}(
    troop_id : felt
) -> (cost : Cost):
    let (cost) = troop_cost.read(troop_id)
    return (cost)
end

#@notice Check if a realm can be attacked
#@param attacking_realm_id: Attacking realm token id
#@param defending_realm_id: Defending realm token id
#@return yesno: Wether a realm can be attacked
@view
func realm_can_be_attacked{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    attacking_realm_id : Uint256, defending_realm_id : Uint256
) -> (yesno : felt):
    # TODO: write tests for this
    # TODO: Cannot attack own Realm

    alloc_locals

    let (controller) = Module.get_controller_address()

    let (realm_combat_data : RealmCombatData) = get_realm_combat_data(defending_realm_id)

    let (now) = get_block_timestamp()
    let diff = now - realm_combat_data.last_attacked_at
    let (was_attacked_recently) = is_le(diff, ATTACK_COOLDOWN_PERIOD)

    if was_attacked_recently == 1:
        return (FALSE)
    end

    # GET COMBAT DATA
    let (realms_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.Realms
    )
    let (s_realms_address) = IModuleController.get_external_contract_address(
        controller, ExternalContractIds.StakedRealms
    )
    let (attacking_realm_data : RealmData) = IRealmsERC721.fetch_realm_data(
        realms_address, attacking_realm_id
    )
    let (defending_realm_data : RealmData) = IRealmsERC721.fetch_realm_data(
        realms_address, defending_realm_id
    )

    if attacking_realm_data.order == defending_realm_data.order:
        # intra-order attacks are not allowed
        return (FALSE)
    end

    # CANNOT ATTACK YOUR OWN
    let (attacking_realm_owner) = IRealmsERC721.ownerOf(s_realms_address, attacking_realm_id)
    let (defending_realm_owner) = IRealmsERC721.ownerOf(s_realms_address, defending_realm_id)

    if attacking_realm_owner == defending_realm_owner:
        return (FALSE)
    end

    return (TRUE)
end

# -----------------------------------
# ADMIN
# -----------------------------------

#@notice Set troop cost admin function
#@param troop_id: Troop id
#@param cost: Troop cost
@external
func set_troop_cost{range_check_ptr, syscall_ptr : felt*, pedersen_ptr : HashBuiltin*}(
    troop_id : felt, cost : Cost
):
    # Proxy_only_admin()
    troop_cost.write(troop_id, cost)
    return ()
end
