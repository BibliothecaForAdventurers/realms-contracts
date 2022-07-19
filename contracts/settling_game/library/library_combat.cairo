%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import (
    assert_not_zero,
    assert_le,
    assert_lt,
    split_int,
    unsigned_div_rem,
)
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.memset import memset
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.lang.compiler.lib.registers import get_fp_and_pc

from contracts.settling_game.utils.game_structs import (
    RealmBuildingsIds,
    Squad,
    SquadStats,
    Troop,
    TroopType,
    TroopId,
    TroopProps,
)

# used for packing
const SHIFT = 0x100

namespace Combat:
    func compute_squad_stats(s : Squad) -> (stats : SquadStats):
        let agility = s.t1_1.agility + s.t1_2.agility + s.t1_3.agility + s.t1_4.agility +
            s.t1_5.agility + s.t1_6.agility + s.t1_7.agility + s.t1_8.agility + s.t1_9.agility +
            s.t2_1.agility + s.t2_2.agility + s.t2_3.agility + s.t2_4.agility + s.t2_5.agility +
            s.t3_1.agility

        let attack = s.t1_1.attack + s.t1_2.attack + s.t1_3.attack + s.t1_4.attack +
            s.t1_5.attack + s.t1_6.attack + s.t1_7.attack + s.t1_8.attack + s.t1_9.attack +
            s.t2_1.attack + s.t2_2.attack + s.t2_3.attack + s.t2_4.attack + s.t2_5.attack +
            s.t3_1.attack

        let armor = s.t1_1.armor + s.t1_2.armor + s.t1_3.armor + s.t1_4.armor +
            s.t1_5.armor + s.t1_6.armor + s.t1_7.armor + s.t1_8.armor + s.t1_9.armor +
            s.t2_1.armor + s.t2_2.armor + s.t2_3.armor + s.t2_4.armor + s.t2_5.armor +
            s.t3_1.armor

        let vitality = s.t1_1.vitality + s.t1_2.vitality + s.t1_3.vitality + s.t1_4.vitality +
            s.t1_5.vitality + s.t1_6.vitality + s.t1_7.vitality + s.t1_8.vitality + s.t1_9.vitality +
            s.t2_1.vitality + s.t2_2.vitality + s.t2_3.vitality + s.t2_4.vitality + s.t2_5.vitality +
            s.t3_1.vitality

        let wisdom = s.t1_1.wisdom + s.t1_2.wisdom + s.t1_3.wisdom + s.t1_4.wisdom +
            s.t1_5.wisdom + s.t1_6.wisdom + s.t1_7.wisdom + s.t1_8.wisdom + s.t1_9.wisdom +
            s.t2_1.wisdom + s.t2_2.wisdom + s.t2_3.wisdom + s.t2_4.wisdom + s.t2_5.wisdom +
            s.t3_1.wisdom

        return (
            SquadStats(agility=agility, attack=attack, armor=armor, vitality=vitality, wisdom=wisdom),
        )
    end

    func compute_squad_vitality(s : Squad) -> (vitality : felt):
        let vitality = s.t1_1.vitality + s.t1_2.vitality + s.t1_3.vitality + s.t1_4.vitality +
            s.t1_5.vitality + s.t1_6.vitality + s.t1_7.vitality + s.t1_8.vitality + s.t1_9.vitality +
            s.t2_1.vitality + s.t2_2.vitality + s.t2_3.vitality + s.t2_4.vitality + s.t2_5.vitality +
            s.t3_1.vitality
        return (vitality)
    end

    func pack_squad{range_check_ptr}(s : Squad) -> (p : felt):
        alloc_locals

        let (pt1_1) = pack_troop(s.t1_1)
        let (pt1_2) = pack_troop(s.t1_2)
        let (pt1_3) = pack_troop(s.t1_3)
        let (pt1_4) = pack_troop(s.t1_4)
        let (pt1_5) = pack_troop(s.t1_5)
        let (pt1_6) = pack_troop(s.t1_6)
        let (pt1_7) = pack_troop(s.t1_7)
        let (pt1_8) = pack_troop(s.t1_8)
        let (pt1_9) = pack_troop(s.t1_9)

        let (pt2_1) = pack_troop(s.t2_1)
        let (pt2_2) = pack_troop(s.t2_2)
        let (pt2_3) = pack_troop(s.t2_3)
        let (pt2_4) = pack_troop(s.t2_4)
        let (pt2_5) = pack_troop(s.t2_5)

        let (pt3_1) = pack_troop(s.t3_1)

        let packed = (
            pt1_1 +
            (pt1_2 * (SHIFT ** 2)) +
            (pt1_3 * (SHIFT ** 4)) +
            (pt1_4 * (SHIFT ** 6)) +
            (pt1_5 * (SHIFT ** 8)) +
            (pt1_6 * (SHIFT ** 10)) +
            (pt1_7 * (SHIFT ** 12)) +
            (pt1_8 * (SHIFT ** 14)) +
            (pt1_9 * (SHIFT ** 16)) +
            (pt2_1 * (SHIFT ** 18)) +
            (pt2_2 * (SHIFT ** 20)) +
            (pt2_3 * (SHIFT ** 22)) +
            (pt2_4 * (SHIFT ** 24)) +
            (pt2_5 * (SHIFT ** 26)) +
            (pt3_1 * (SHIFT ** 28)))

        return (packed)
    end

    func unpack_squad{range_check_ptr}(p : felt) -> (s : Squad):
        alloc_locals

        let (p_out : felt*) = alloc()
        split_int(p, 15, SHIFT ** 2, 2 ** 16, p_out)

        let (t1_1) = unpack_troop([p_out])
        let (t1_2) = unpack_troop([p_out + 1])
        let (t1_3) = unpack_troop([p_out + 2])
        let (t1_4) = unpack_troop([p_out + 3])
        let (t1_5) = unpack_troop([p_out + 4])
        let (t1_6) = unpack_troop([p_out + 5])
        let (t1_7) = unpack_troop([p_out + 6])
        let (t1_8) = unpack_troop([p_out + 7])
        let (t1_9) = unpack_troop([p_out + 8])
        let (t2_1) = unpack_troop([p_out + 9])
        let (t2_2) = unpack_troop([p_out + 10])
        let (t2_3) = unpack_troop([p_out + 11])
        let (t2_4) = unpack_troop([p_out + 12])
        let (t2_5) = unpack_troop([p_out + 13])
        let (t3_1) = unpack_troop([p_out + 14])

        return (
            Squad(t1_1=t1_1, t1_2=t1_2, t1_3=t1_3, t1_4=t1_4, t1_5=t1_5,
            t1_6=t1_6, t1_7=t1_7, t1_8=t1_8, t1_9=t1_9, t2_1=t2_1, t2_2=t2_2,
            t2_3=t2_3, t2_4=t2_4, t2_5=t2_5, t3_1=t3_1),
        )
    end

    func pack_troop{range_check_ptr}(t : Troop) -> (packed : felt):
        assert_lt(t.id, TroopId.SIZE)
        assert_le(t.vitality, 255)
        let packed = t.id + t.vitality * SHIFT
        return (packed)
    end

    func unpack_troop{range_check_ptr}(packed : felt) -> (t : Troop):
        alloc_locals
        let (_foo) = alloc()
        let (vitality, troop_id) = unsigned_div_rem(packed, SHIFT)
        if troop_id == 0:
            return (
                Troop(id=0, type=0, tier=0, building=0, agility=0, attack=0, armor=0, vitality=0, wisdom=0),
            )
        end
        let (type, tier, building, agility, attack, armor, _, wisdom) = get_troop_properties(
            troop_id
        )

        return (
            Troop(id=troop_id, type=type, tier=tier, building=building,
            agility=agility, attack=attack, armor=armor, vitality=vitality, wisdom=wisdom),
        )
    end

    func get_troop_properties{range_check_ptr}(troop_id : felt) -> (
        type, tier, building, agility, attack, armor, vitality, wisdom
    ):
        assert_not_zero(troop_id)
        assert_lt(troop_id, TroopId.SIZE)

        let idx = troop_id - 1
        let (type_label) = get_label_location(troop_types_per_id)
        let (tier_label) = get_label_location(troop_tier_per_id)
        let (building_label) = get_label_location(troop_building_per_id)
        let (agility_label) = get_label_location(troop_agility_per_id)
        let (attack_label) = get_label_location(troop_attack_per_id)
        let (armor_label) = get_label_location(troop_armor_per_id)
        let (vitality_label) = get_label_location(troop_vitality_per_id)
        let (wisdom_label) = get_label_location(troop_wisdom_per_id)

        return (
            [type_label + idx],
            [tier_label + idx],
            [building_label + idx],
            [agility_label + idx],
            [attack_label + idx],
            [armor_label + idx],
            [vitality_label + idx],
            [wisdom_label + idx],
        )

        troop_types_per_id:
        dw TroopProps.Type.Skirmisher
        dw TroopProps.Type.Longbow
        dw TroopProps.Type.Crossbow
        dw TroopProps.Type.Pikeman
        dw TroopProps.Type.Knight
        dw TroopProps.Type.Paladin
        dw TroopProps.Type.Ballista
        dw TroopProps.Type.Mangonel
        dw TroopProps.Type.Trebuchet
        dw TroopProps.Type.Apprentice
        dw TroopProps.Type.Mage
        dw TroopProps.Type.Arcanist

        troop_tier_per_id:
        dw TroopProps.Tier.Skirmisher
        dw TroopProps.Tier.Longbow
        dw TroopProps.Tier.Crossbow
        dw TroopProps.Tier.Pikeman
        dw TroopProps.Tier.Knight
        dw TroopProps.Tier.Paladin
        dw TroopProps.Tier.Ballista
        dw TroopProps.Tier.Mangonel
        dw TroopProps.Tier.Trebuchet
        dw TroopProps.Tier.Apprentice
        dw TroopProps.Tier.Mage
        dw TroopProps.Tier.Arcanist

        troop_building_per_id:
        dw TroopProps.Building.Skirmisher
        dw TroopProps.Building.Longbow
        dw TroopProps.Building.Crossbow
        dw TroopProps.Building.Pikeman
        dw TroopProps.Building.Knight
        dw TroopProps.Building.Paladin
        dw TroopProps.Building.Ballista
        dw TroopProps.Building.Mangonel
        dw TroopProps.Building.Trebuchet
        dw TroopProps.Building.Apprentice
        dw TroopProps.Building.Mage
        dw TroopProps.Building.Arcanist

        troop_agility_per_id:
        dw TroopProps.Agility.Skirmisher
        dw TroopProps.Agility.Longbow
        dw TroopProps.Agility.Crossbow
        dw TroopProps.Agility.Pikeman
        dw TroopProps.Agility.Knight
        dw TroopProps.Agility.Paladin
        dw TroopProps.Agility.Ballista
        dw TroopProps.Agility.Mangonel
        dw TroopProps.Agility.Trebuchet
        dw TroopProps.Agility.Apprentice
        dw TroopProps.Agility.Mage
        dw TroopProps.Agility.Arcanist

        troop_attack_per_id:
        dw TroopProps.Attack.Skirmisher
        dw TroopProps.Attack.Longbow
        dw TroopProps.Attack.Crossbow
        dw TroopProps.Attack.Pikeman
        dw TroopProps.Attack.Knight
        dw TroopProps.Attack.Paladin
        dw TroopProps.Attack.Ballista
        dw TroopProps.Attack.Mangonel
        dw TroopProps.Attack.Trebuchet
        dw TroopProps.Attack.Apprentice
        dw TroopProps.Attack.Mage
        dw TroopProps.Attack.Arcanist

        troop_armor_per_id:
        dw TroopProps.Armor.Skirmisher
        dw TroopProps.Armor.Longbow
        dw TroopProps.Armor.Crossbow
        dw TroopProps.Armor.Pikeman
        dw TroopProps.Armor.Knight
        dw TroopProps.Armor.Paladin
        dw TroopProps.Armor.Ballista
        dw TroopProps.Armor.Mangonel
        dw TroopProps.Armor.Trebuchet
        dw TroopProps.Armor.Apprentice
        dw TroopProps.Armor.Mage
        dw TroopProps.Armor.Arcanist

        troop_vitality_per_id:
        dw TroopProps.Vitality.Skirmisher
        dw TroopProps.Vitality.Longbow
        dw TroopProps.Vitality.Crossbow
        dw TroopProps.Vitality.Pikeman
        dw TroopProps.Vitality.Knight
        dw TroopProps.Vitality.Paladin
        dw TroopProps.Vitality.Ballista
        dw TroopProps.Vitality.Mangonel
        dw TroopProps.Vitality.Trebuchet
        dw TroopProps.Vitality.Apprentice
        dw TroopProps.Vitality.Mage
        dw TroopProps.Vitality.Arcanist

        troop_wisdom_per_id:
        dw TroopProps.Wisdom.Skirmisher
        dw TroopProps.Wisdom.Longbow
        dw TroopProps.Wisdom.Crossbow
        dw TroopProps.Wisdom.Pikeman
        dw TroopProps.Wisdom.Knight
        dw TroopProps.Wisdom.Paladin
        dw TroopProps.Wisdom.Ballista
        dw TroopProps.Wisdom.Mangonel
        dw TroopProps.Wisdom.Trebuchet
        dw TroopProps.Wisdom.Apprentice
        dw TroopProps.Wisdom.Mage
        dw TroopProps.Wisdom.Arcanist
    end

    func get_troop_internal{range_check_ptr}(troop_id : felt) -> (t : Troop):
        with_attr error_message("Combat: unknown troop ID"):
            assert_not_zero(troop_id)
            assert_lt(troop_id, TroopId.SIZE)
        end

        let (type, tier, building, agility, attack, armor, vitality, wisdom) = get_troop_properties(
            troop_id
        )
        return (
            Troop(id=troop_id, type=type, tier=tier, building=building,
            agility=agility, attack=attack, armor=armor, vitality=vitality, wisdom=wisdom),
        )
    end

    func add_troop_to_squad(t : Troop, s : Squad) -> (updated : Squad):
        alloc_locals
        let (__fp__, _) = get_fp_and_pc()
        let (free_slot) = find_first_free_troop_slot_in_squad(s, t.tier)
        let (a) = alloc()

        memcpy(a, &s, free_slot)
        memcpy(a + free_slot, &t, Troop.SIZE)
        memcpy(
            a + free_slot + Troop.SIZE,
            &s + free_slot + Troop.SIZE,
            Squad.SIZE - free_slot - Troop.SIZE,
        )

        let updated = cast(a, Squad*)
        return ([updated])
    end

    func remove_troop_from_squad{range_check_ptr}(troop_idx : felt, s : Squad) -> (updated : Squad):
        alloc_locals
        assert_lt(troop_idx, Squad.SIZE / Troop.SIZE)

        let (__fp__, _) = get_fp_and_pc()
        let (a) = alloc()

        memcpy(a, &s, troop_idx * Troop.SIZE)
        memset(a + troop_idx * Troop.SIZE, 0, Troop.SIZE)
        memcpy(
            a + (troop_idx + 1) * Troop.SIZE,
            &s + (troop_idx + 1) * Troop.SIZE,
            Squad.SIZE - (troop_idx + 1) * Troop.SIZE,
        )

        let updated = cast(a, Squad*)
        return ([updated])
    end

    func find_first_free_troop_slot_in_squad(s : Squad, tier : felt) -> (free_slot_index : felt):
        # type == 0 just means the slot is free (0 is the default, if no Troop was assigned there, it's going to be 0)
        if tier == 1:
            if s.t1_1.type == 0:
                return (0)
            end
            if s.t1_2.type == 0:
                return (Troop.SIZE)
            end
            if s.t1_3.type == 0:
                return (Troop.SIZE * 2)
            end
            if s.t1_4.type == 0:
                return (Troop.SIZE * 3)
            end
            if s.t1_5.type == 0:
                return (Troop.SIZE * 4)
            end
            if s.t1_6.type == 0:
                return (Troop.SIZE * 5)
            end
            if s.t1_7.type == 0:
                return (Troop.SIZE * 6)
            end
            if s.t1_8.type == 0:
                return (Troop.SIZE * 7)
            end
            if s.t1_9.type == 0:
                return (Troop.SIZE * 8)
            end
        end

        if tier == 2:
            if s.t2_1.type == 0:
                return (Troop.SIZE * 9)
            end
            if s.t2_2.type == 0:
                return (Troop.SIZE * 10)
            end
            if s.t2_3.type == 0:
                return (Troop.SIZE * 11)
            end
            if s.t2_4.type == 0:
                return (Troop.SIZE * 12)
            end
            if s.t2_5.type == 0:
                return (Troop.SIZE * 13)
            end
        end

        if tier == 3:
            if s.t3_1.type == 0:
                return (Troop.SIZE * 14)
            end
        end

        with_attr error_message("Combat: no free troop slot in squad"):
            assert 1 = 0
        end

        return (0)
    end

    func add_troops_to_squad{range_check_ptr}(
        current : Squad, troop_ids_len : felt, troop_ids : felt*
    ) -> (squad : Squad):
        alloc_locals

        if troop_ids_len == 0:
            return (current)
        end

        let (troop : Troop) = get_troop_internal([troop_ids])
        let (updated : Squad) = add_troop_to_squad(troop, current)

        return add_troops_to_squad(updated, troop_ids_len - 1, troop_ids + 1)
    end

    func remove_troops_from_squad{range_check_ptr}(
        current : Squad, troop_idxs_len : felt, troop_idxs : felt*
    ) -> (squad : Squad):
        alloc_locals

        if troop_idxs_len == 0:
            return (current)
        end

        let (updated : Squad) = remove_troop_from_squad([troop_idxs], current)
        return remove_troops_from_squad(updated, troop_idxs_len - 1, troop_idxs + 1)
    end

    func get_troop_population{range_check_ptr}(squad : felt) -> (population : felt):
        alloc_locals

        let (s : Squad) = unpack_squad(squad)
        tempvar p = 0
        if s.t1_1.id != 0:
            tempvar p = p + 1
        end
        if s.t1_2.id != 0:
            tempvar p = p + 1
        end
        if s.t1_3.id != 0:
            tempvar p = p + 1
        end
        if s.t1_4.id != 0:
            tempvar p = p + 1
        end
        if s.t1_5.id != 0:
            tempvar p = p + 1
        end
        if s.t1_6.id != 0:
            tempvar p = p + 1
        end
        if s.t1_7.id != 0:
            tempvar p = p + 1
        end
        if s.t1_8.id != 0:
            tempvar p = p + 1
        end
        if s.t1_9.id != 0:
            tempvar p = p + 1
        end
        if s.t2_1.id != 0:
            tempvar p = p + 1
        end
        if s.t2_2.id != 0:
            tempvar p = p + 1
        end
        if s.t2_3.id != 0:
            tempvar p = p + 1
        end
        if s.t2_4.id != 0:
            tempvar p = p + 1
        end
        if s.t2_5.id != 0:
            tempvar p = p + 1
        end
        if s.t3_1.id != 0:
            tempvar p = p + 1
        end

        return (p)
    end

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

        let (t2_1, remaining_hits) = hit_troop(s.t2_1, remaining_hits)
        let (t2_2, remaining_hits) = hit_troop(s.t2_2, remaining_hits)
        let (t2_3, remaining_hits) = hit_troop(s.t2_3, remaining_hits)
        let (t2_4, remaining_hits) = hit_troop(s.t2_4, remaining_hits)
        let (t2_5, remaining_hits) = hit_troop(s.t2_5, remaining_hits)

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
            t2_1=t2_1,
            t2_2=t2_2,
            t2_3=t2_3,
            t2_4=t2_4,
            t2_5=t2_5,
            t3_1=t3_1,
        )

        return (s)
    end

    func hit_troop{range_check_ptr}(t : Troop, hits : felt) -> (
        hit_troop : Troop, remaining_hits : felt
    ):
        if hits == 0:
            return (t, 0)
        end

        let (kills_troop) = is_le(t.vitality, hits)
        if kills_troop == 1:
            # t.vitality <= hits
            let ht = Troop(
                id=0, type=0, tier=0, building=0, agility=0, attack=0, armor=0, vitality=0, wisdom=0
            )
            let rem = hits - t.vitality
            return (ht, rem)
        else:
            # t.vitality > hits
            let ht = Troop(
                id=t.id,
                type=t.type,
                tier=t.tier,
                building=t.building,
                agility=t.agility,
                attack=t.attack,
                armor=t.armor,
                vitality=t.vitality - hits,
                wisdom=t.wisdom,
            )
            return (ht, 0)
        end
    end
end
