class Block {
    vec3 Position;

    Block(CGameCtnBlock@ block) {
        Position = GetBlockPosition(block);
    }
}

const uint16 O_BLOCK_FREEPOS = Reflection::GetType("CGameCtnBlock").GetMember("Dir").Offset + 0x8;
const uint16 FreeBlockRotOffset = O_BLOCK_FREEPOS + 0xC;

vec3 GetBlockPosition(CGameCtnBlock@ block) {
    if (block.CoordX > 2000000000) {
        // ghost block -- https://git.virtit.fr/beu/Openplanet-Plugins/src/branch/master/BlocksItemsCounter/Source/Libs/Objects.as#L55
        return Dev::GetOffsetVec3(block, O_BLOCK_FREEPOS);
    } else {
        return vec3(block.CoordX, block.CoordY, block.CoordZ) * vec3(32, 8, 32) + vec3(0, -56, 0);
    }
}

int3 PositionToCoords(vec3 pos) {
    vec3 ret = (pos - vec3(16, -60, 16)) / vec3(32, 8, 32);
    return int3(int(ret.x), int(ret.y), int(ret.z));
}

//
// Below is selectively copied from E++
//

vec3 GetBlockSpawnLoc(CGameCtnBlock@ block) {
    auto bvx = block.BlockInfoVariantIndex;
    auto variant = GetVariant(block.BlockModel, bvx, block.IsGround);
    return variant.SpawnTrans;
}

CGameCtnBlockInfoVariant@ GetVariant(CGameCtnBlockInfo@ model, uint bvx, bool isGround) {
    if (bvx == 0) {
        if (isGround) {
            return model.VariantBaseGround;
        } else {
            return model.VariantBaseAir;
        }
    }
    bvx--;
    if (isGround) {
        return model.AdditionalVariantsGround[bvx];
    }
    return model.AdditionalVariantsAir[bvx];
}


mat4 GetBlockRotationMatrix(CGameCtnBlock@ block) {
    return EulerToMat(GetBlockRotation(block));
}

vec3 GetBlockRotation(CGameCtnBlock@ block) {
    if (IsBlockFree(block)) {
        // free block mode
        auto ypr = Dev::GetOffsetVec3(block, FreeBlockRotOffset);
        return vec3(ypr.y, ypr.x, ypr.z);
    }
    return vec3(0, CardinalDirectionToYaw(int(block.Dir)), 0);
}

bool IsBlockFree(CGameCtnBlock@ block) {
    return int(block.CoordX) < 0;
}

const double TAU = 6.28318530717958647692;
const double PI = TAU / 2.;
const double HALF_PI = TAU / 4.;
const double NegPI = PI * -1.0;

float CardinalDirectionToYaw(int dir) {
    return NormalizeAngle(double(dir % 4) * HALF_PI * -1.);
}

float NormalizeAngle(float angle) {
    float orig = angle;
    uint count = 0;
    while (angle < NegPI && count < 100) {
        angle += TAU;
        count++;
    }
    while (angle >= PI && count < 100) {
        angle -= TAU;
        count++;
    }
    if (count >= 100) {
        print("NormalizeAngle: count >= 100, " + orig + " -> " + angle);
    }
    return angle;
}

vec3 GetItemModelSpawnLoc(CGameItemModel@ model) {
    auto ciem = cast<CGameCommonItemEntityModel>(model.EntityModel);
    if (ciem !is null) {
        return vec3(ciem.SpawnLoc.tx, ciem.SpawnLoc.ty, ciem.SpawnLoc.tz);
    }
    return vec3(0, 0, 0);
}

vec3 GetItemRotation(CGameCtnAnchoredObject@ item) {
    return vec3(
        item.Pitch,
        item.Yaw,
        item.Roll
    );
}

// From Rxelux's `mat4x` lib, modified
mat4 EulerToMat(vec3 euler) {
    // mat4 translation = mat4::Translate(position*-1);
    mat4 pitch = mat4::Rotate(-euler.x,vec3(1,0,0));
    mat4 roll = mat4::Rotate(-euler.z,vec3(0,0,1));
    mat4 yaw = mat4::Rotate(-euler.y,vec3(0,1,0));
    return mat4::Inverse(pitch*roll*yaw/* *translation */);
}
