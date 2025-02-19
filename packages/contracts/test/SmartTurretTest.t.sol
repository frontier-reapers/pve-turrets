// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/Test.sol";
import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";
import { getKeysWithValue } from "@latticexyz/world-modules/src/modules/keyswithvalue/getKeysWithValue.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";

import { console } from "forge-std/console.sol";

import { IBaseWorld } from "@eveworld/world/src/codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { InventoryItem } from "@eveworld/world/src/modules/inventory/types.sol";
import { Utils as SmartDeployableUtils } from "@eveworld/world/src/modules/smart-deployable/Utils.sol";
import { SmartDeployableLib } from "@eveworld/world/src/modules/smart-deployable/SmartDeployableLib.sol";
import { Coord, WorldPosition, EntityRecordData } from "@eveworld/world/src/modules/smart-storage-unit/types.sol";
import { SmartObjectData } from "@eveworld/world/src/modules/smart-deployable/types.sol";
import { FRONTIER_WORLD_DEPLOYMENT_NAMESPACE } from "@eveworld/common-constants/src/constants.sol";
import { GlobalDeployableState } from "@eveworld/world/src/codegen/tables/GlobalDeployableState.sol";
import { SmartTurretLib } from "@eveworld/world/src/modules/smart-turret/SmartTurretLib.sol";
import { EntityRecordLib } from "@eveworld/world/src/modules/entity-record/EntityRecordLib.sol";
import { SmartCharacterLib } from "@eveworld/world/src/modules/smart-character/SmartCharacterLib.sol";
import { EntityRecordData as CharacterEntityRecord } from "@eveworld/world/src/modules/smart-character/types.sol";
import { EntityRecordOffchainTableData } from "@eveworld/world/src/codegen/tables/EntityRecordOffchainTable.sol";
import { CharactersByAddressTable } from "@eveworld/world/src/codegen/tables/CharactersByAddressTable.sol";
import { DeployableState, DeployableStateData } from "@eveworld/world/src/codegen/tables/DeployableState.sol";
import { State } from "@eveworld/world/src/modules/smart-deployable/types.sol";
import { EphemeralInvItemTableData, EphemeralInvItemTable } from "@eveworld/world/src/codegen/tables/EphemeralInvItemTable.sol";
import { GlobalDeployableState } from "@eveworld/world/src/codegen/tables/GlobalDeployableState.sol";

import { IWorld } from "../src/codegen/world/IWorld.sol";
import { Utils } from "../src/systems/Utils.sol";

import { SmartTurretSystem } from "../src/systems/SmartTurretSystem.sol";
import { TargetPriority, Turret, SmartTurretTarget } from "@eveworld/world/src/modules/smart-turret/types.sol";

contract SmartTurretTest is MudTest {
  using SmartDeployableLib for SmartDeployableLib.World;
  using SmartTurretLib for SmartTurretLib.World;
  using EntityRecordLib for EntityRecordLib.World;
  using SmartCharacterLib for SmartCharacterLib.World;
  using SmartDeployableUtils for bytes14;

  SmartDeployableLib.World smartDeployable;
  SmartTurretLib.World smartTurret;
  EntityRecordLib.World entityRecord;
  SmartCharacterLib.World smartCharacter;
  ResourceId systemId = Utils.smartTurretSystemId();

  IWorld world;

  uint256 smartTurretId;
  uint256 ownerCharacterId = 11111;

  uint256 playerCharacterId = 100;

  uint256 player2CharacterId = 200;
  uint256 player3CharacterId = 300;

  uint256 npcCharacterId = 10000001;

  //Setup for the tests
  function setUp() public override {
    super.setUp();
    world = IWorld(worldAddress);

    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address admin = vm.addr(deployerPrivateKey);

    uint256 playerPrivateKey = vm.envUint("TEST_PLAYER_PRIVATE_KEY");
    address player = vm.addr(playerPrivateKey);

    //Create a second and third player for testing. The address is randomly generated
    address player2 = address(0x280Efa9b3A0c1608119fB01f2Df0AFCcA1c7EA3d);
    address player3 = address(0xd628d44B1ca0B1240152B282F4f88bDE93347aac);
    address npc = address(0x111122223333444455556666777788889999aAaa);

    smartDeployable = SmartDeployableLib.World({
      iface: IBaseWorld(worldAddress),
      namespace: FRONTIER_WORLD_DEPLOYMENT_NAMESPACE
    });
    smartTurret = SmartTurretLib.World({
      iface: IBaseWorld(worldAddress),
      namespace: FRONTIER_WORLD_DEPLOYMENT_NAMESPACE
    });

    entityRecord = EntityRecordLib.World({
      iface: IBaseWorld(worldAddress),
      namespace: FRONTIER_WORLD_DEPLOYMENT_NAMESPACE
    });

    smartCharacter = SmartCharacterLib.World({
      iface: IBaseWorld(worldAddress),
      namespace: FRONTIER_WORLD_DEPLOYMENT_NAMESPACE
    });

    if (CharactersByAddressTable.get(admin) == 0) {
      smartCharacter.createCharacter(
        ownerCharacterId, //characterID
        admin, //characterAddress
        1, //corpID
        CharacterEntityRecord({ typeId: 123, itemId: 234, volume: 100 }),
        EntityRecordOffchainTableData({ name: "admin", dappURL: "noURL", description: "." }),
        ""
      );
    }
    if (CharactersByAddressTable.get(player) == 0) {
      smartCharacter.createCharacter(
        playerCharacterId, //characterID
        player, //characterAddress
        200004, //corpID
        CharacterEntityRecord({ typeId: 123, itemId: 234, volume: 100 }),
        EntityRecordOffchainTableData({ name: "testPlayer", dappURL: "noURL", description: "." }),
        ""
      );
    }
    if (CharactersByAddressTable.get(player2) == 0) {
      smartCharacter.createCharacter(
        player2CharacterId, //characterID
        player2, //characterAddress
        200008, //corpID
        CharacterEntityRecord({ typeId: 123, itemId: 234, volume: 100 }),
        EntityRecordOffchainTableData({ name: "testPlayer2", dappURL: "noURL", description: "." }),
        ""
      );
    }
    if (CharactersByAddressTable.get(player3) == 0) {
      smartCharacter.createCharacter(
        player3CharacterId, //characterID
        player3, //characterAddress
        200008, //corpID
        CharacterEntityRecord({ typeId: 123, itemId: 234, volume: 100 }),
        EntityRecordOffchainTableData({ name: "testPlayer3", dappURL: "noURL", description: "." }),
        ""
      );
    }

    if (CharactersByAddressTable.get(npc) == 0) {
      smartCharacter.createCharacter(
        npcCharacterId, //characterID
        npc, //characterAddress
        0, //corpID
        CharacterEntityRecord({ typeId: 123, itemId: 234, volume: 100 }),
        EntityRecordOffchainTableData({ name: "mooneater", dappURL: "noURL", description: "." }),
        ""
      );
    }

    smartTurretId = vm.envUint("SMART_TURRET_ID");
    createAnchorAndOnline(smartTurretId, admin);
  }

  //Test if the world exists
  function testWorldExists() public {
    uint256 codeSize;
    address addr = worldAddress;
    assembly {
      codeSize := extcodesize(addr)
    }
    assertTrue(codeSize > 0);
  }

  //Test inProximity with a player that should not be targeted
  function testInProximityInCorp() public {
    //Execute inProximity view function and see what is returns
    TargetPriority[] memory priorityQueue = new TargetPriority[](0);
    Turret memory turret = Turret({ weaponTypeId: 1, ammoTypeId: 1, chargesLeft: 100 });

    //Total Weight: 0
    SmartTurretTarget memory turretTarget = SmartTurretTarget({
      shipId: 1,
      shipTypeId: 1,
      characterId: ownerCharacterId,
      hpRatio: 100,
      shieldRatio: 100,
      armorRatio: 100
    });

    //Run inProximity
    TargetPriority[] memory returnTargetQueue = abi.decode(
      world.call(
        systemId,
        abi.encodeCall(
          SmartTurretSystem.inProximity,
          (smartTurretId, ownerCharacterId, priorityQueue, turret, turretTarget)
        )
      ),
      (TargetPriority[])
    );

    assertEq(returnTargetQueue.length, 0, "There should be no targets");
  }

  function testInProximityMooneater() public {
    // Execute inProximity view function and see what is returns
    TargetPriority[] memory priorityQueue = new TargetPriority[](0);
    Turret memory turret = Turret({ weaponTypeId: 1, ammoTypeId: 1, chargesLeft: 100 });

    //Total Weight: 0
    SmartTurretTarget memory turretTarget = SmartTurretTarget({
      shipId: 1,
      shipTypeId: 83487,
      characterId: npcCharacterId,
      hpRatio: 100,
      shieldRatio: 100,
      armorRatio: 100
    });

    //Run inProximity
    TargetPriority[] memory returnTargetQueue = abi.decode(
      world.call(
        systemId,
        abi.encodeCall(
          SmartTurretSystem.inProximity,
          (smartTurretId, ownerCharacterId, priorityQueue, turret, turretTarget)
        )
      ),
      (TargetPriority[])
    );

    assertEq(returnTargetQueue.length, 1, "There should be 1 targets");
  }

  function testInProximityNotInCorpNew() public {
    //Execute inProximity view function and see what is returns
    TargetPriority[] memory priorityQueue = new TargetPriority[](0);
    Turret memory turret = Turret({ weaponTypeId: 1, ammoTypeId: 1, chargesLeft: 100 });

    //Total Weight: 0
    SmartTurretTarget memory turretTarget = SmartTurretTarget({
      shipId: 1,
      shipTypeId: 1,
      characterId: playerCharacterId,
      hpRatio: 100,
      shieldRatio: 100,
      armorRatio: 100
    });

    //Run inProximity
    TargetPriority[] memory returnTargetQueue = abi.decode(
      world.call(
        systemId,
        abi.encodeCall(
          SmartTurretSystem.inProximity,
          (smartTurretId, ownerCharacterId, priorityQueue, turret, turretTarget)
        )
      ),
      (TargetPriority[])
    );

    assertEq(returnTargetQueue.length, 0, "There should be 0 targets");
  }

  //Test aggression
  function testAggression() public {
    TargetPriority[] memory priorityQueue = new TargetPriority[](1);
    Turret memory turret = Turret({ weaponTypeId: 1, ammoTypeId: 1, chargesLeft: 100 });
    SmartTurretTarget memory turretTarget = SmartTurretTarget({
      shipId: 1,
      shipTypeId: 1,
      characterId: 4444,
      hpRatio: 50,
      shieldRatio: 50,
      armorRatio: 50
    });
    SmartTurretTarget memory aggressor = SmartTurretTarget({
      shipId: 1,
      shipTypeId: 1,
      characterId: 5555,
      hpRatio: 100,
      shieldRatio: 100,
      armorRatio: 100
    });
    SmartTurretTarget memory victim = SmartTurretTarget({
      shipId: 1,
      shipTypeId: 1,
      characterId: 6666,
      hpRatio: 80,
      shieldRatio: 100,
      armorRatio: 100
    });

    priorityQueue[0] = TargetPriority({ target: turretTarget, weight: 100 });

    //Run aggression
    TargetPriority[] memory returnTargetQueue = abi.decode(
      world.call(
        systemId,
        abi.encodeCall(
          SmartTurretSystem.aggression,
          (smartTurretId, ownerCharacterId, priorityQueue, turret, aggressor, victim)
        )
      ),
      (TargetPriority[])
    );

    assertEq(returnTargetQueue.length, 1, "Target length should equal 1");
  }

  function createAnchorAndOnline(uint256 newSmartTurretId, address admin) private {
    assert(newSmartTurretId != 0);

    //Create and anchor the smart turret and bring online
    smartTurret.createAndAnchorSmartTurret(
      newSmartTurretId,
      EntityRecordData({ typeId: 7888, itemId: 111, volume: 10 }),
      SmartObjectData({ owner: admin, tokenURI: "test" }),
      WorldPosition({ solarSystemId: 1, position: Coord({ x: 1, y: 1, z: 1 }) }),
      1e18, // fuelUnitVolume,
      1, // fuelConsumptionPerMinute,
      1000000 * 1e18 // fuelMaxCapacity,
    );

    // check global state and resume if needed
    if (GlobalDeployableState.getIsPaused() == false) {
      smartDeployable.globalResume();
    }

    smartDeployable.depositFuel(smartTurretId, 200010);
    smartDeployable.bringOnline(smartTurretId);
  }
}
