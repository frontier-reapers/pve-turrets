// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { console } from "forge-std/console.sol";
import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";
import { WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { IBaseWorld } from "@latticexyz/world/src/codegen/interfaces/IBaseWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";

import { IERC20 } from "@latticexyz/world-modules/src/modules/erc20-puppet/IERC20.sol";
import { IERC721 } from "@eveworld/world/src/modules/eve-erc721-puppet/IERC721.sol";

import { DeployableTokenTable } from "@eveworld/world/src/codegen/tables/DeployableTokenTable.sol";
import { EntityRecordTable, EntityRecordTableData } from "@eveworld/world/src/codegen/tables/EntityRecordTable.sol";
import { Utils as EntityRecordUtils } from "@eveworld/world/src/modules/entity-record/Utils.sol";
import { Utils as SmartDeployableUtils } from "@eveworld/world/src/modules/smart-deployable/Utils.sol";
import { FRONTIER_WORLD_DEPLOYMENT_NAMESPACE as DEPLOYMENT_NAMESPACE } from "@eveworld/common-constants/src/constants.sol";

import { Utils as SmartCharacterUtils } from "@eveworld/world/src/modules/smart-character/Utils.sol";
import { CharactersTableData, CharactersTable } from "@eveworld/world/src/codegen/tables/CharactersTable.sol";
import { TargetPriority, Turret, SmartTurretTarget } from "@eveworld/world/src/modules/smart-turret/types.sol";

import { Utils } from "./Utils.sol";
import { AccessControl } from "@latticexyz/world/src/AccessControl.sol";

/**
 * @dev This contract is an example for implementing logic to a smart turret
 */
contract SmartTurretSystem is System {
  using EntityRecordUtils for bytes14;
  using SmartDeployableUtils for bytes14;
  using SmartCharacterUtils for bytes14;

  error InvalidSmartTurretId(uint256 smartTurretId);
  error InvalidCharacterId(uint256 characterId);
  error InvalidTurret(Turret turret);
  error InvalidTarget(SmartTurretTarget target);

  /**
   * @dev a function to implement logic for Smart Turret based on proximity
   * @param smartTurretId The Smart Turret id
   * @param characterId is the owner of the Smart Turret
   * @param priorityQueue is the queue of existing targets ordered by priority, index 0 being the lowest priority
   * @param turret is the turret data
   * @param turretTarget is the player in the zone
   * This runs on a tick based cycle when the player is in proximity of the Smart Turret
   * The game receives the new priority queue, and select targets based on the reverse order of the new queue. Meaning the targets with the highest index will be picked first.
   */
  function inProximity(
    uint256 smartTurretId,
    uint256 characterId,
    TargetPriority[] memory priorityQueue,
    Turret memory turret,
    SmartTurretTarget memory turretTarget
  ) public returns (TargetPriority[] memory updatedPriorityQueue) {
    if (smartTurretId == 0) {
      revert InvalidSmartTurretId(smartTurretId);
    }

    if (characterId == 0) {
      revert InvalidCharacterId(characterId);
    }

    if (turret.weaponTypeId == 0 || turret.ammoTypeId == 0) {
      revert InvalidTurret(turret);
    }

    if (turretTarget.shipTypeId == 83487) {
      TargetPriority[] memory tempArray = new TargetPriority[](1);
      tempArray[0] = TargetPriority({ target: turretTarget, weight: 100 });
      return tempArray;
    }

    return priorityQueue;
  }

  /**
   * @dev a function to implement logic for smart turret based on aggression
   * @param smartTurretId The smart turret id
   * @param characterId is the owner of the smart turret
   * @param priorityQueue is the queue of existing targets ordered by priority, index 0 being the lowest priority
   * @param turret is the turret data
   * @param aggressor is the aggressor
   * @param victim is the victim
   */
  function aggression(
    uint256 smartTurretId,
    uint256 characterId,
    TargetPriority[] memory priorityQueue,
    Turret memory turret,
    SmartTurretTarget memory aggressor,
    SmartTurretTarget memory victim
  ) public returns (TargetPriority[] memory updatedPriorityQueue) {
    if (smartTurretId == 0) {
      revert InvalidSmartTurretId(smartTurretId);
    }

    if (characterId == 0) {
      revert InvalidCharacterId(characterId);
    }

    if (turret.weaponTypeId == 0 || turret.ammoTypeId == 0) {
      revert InvalidTurret(turret);
    }

    if (aggressor.characterId == 0 || aggressor.shipId == 0 || aggressor.shipTypeId == 0) {
      revert InvalidTarget(aggressor);
    }
    
    if (victim.characterId == 0 || victim.shipId == 0 || victim.shipTypeId == 0) {
      revert InvalidTarget(victim);
    }

    if (aggressor.shipTypeId == 83487) {
      TargetPriority[] memory tempArray = new TargetPriority[](1);
      tempArray[0] = TargetPriority({ target: aggressor, weight: 100 });
      return tempArray;
    }

    return priorityQueue;
  }

  function _namespace() internal pure returns (bytes14 namespace) {
    return DEPLOYMENT_NAMESPACE;
  }
}
