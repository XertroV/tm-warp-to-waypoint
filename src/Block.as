class Block {
    vec3 Position;

    Block(CGameCtnBlock@ block) {
        Position = GetBlockPosition(block);
    }
}

vec3 GetBlockPosition(CGameCtnBlock@ block) {
    if (block.CoordX > 2000000000) {
        // ghost block
        return Dev::GetOffsetVec3(block, 0x6c) + vec3(16, 4, 16);
    } else {
        // todo: pluginmaptype or calculate
        return vec3(block.CoordX, block.CoordY, block.CoordZ) * vec3(32, 8, 32) + vec3(16, -60, 16);
    }
}

int3 PositionToCoords(vec3 pos) {
    vec3 ret = (pos - vec3(16, -60, 16)) / vec3(32, 8, 32);
    return int3(int(ret.x), int(ret.y), int(ret.z));
}
