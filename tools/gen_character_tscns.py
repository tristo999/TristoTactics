"""
Generate ArcherCharacter.tscn, GoblinCharacter.tscn, and EnemyCharacter.tscn
with 8 directional animations (idle_up/down/left/right + walk_up/down/left/right).
"""
from pathlib import Path

PROJ = Path(__file__).resolve().parent.parent
SCENES = PROJ / "scenes" / "characters"

# Config: (filename, uid, script_path, script_id, idle_texture_path, idle_texture_uid, idle_tex_id, walk_texture_path, walk_tex_id, node_name)
CHARACTERS = [
    {
        "filename": "ArcherCharacter.tscn",
        "scene_uid": 'uid="uid://c7archer1char"',
        "script_path": "res://scripts/characters/base/archer_character.gd",
        "script_id": "1_archer",
        "idle_path": "res://assets/sprites/characters/archer_idle.png",
        "idle_uid": 'uid="uid://bek7dllvhxeoy"',
        "idle_id": "2_archspr",
        "walk_path": "res://assets/sprites/characters/archer_walk.png",
        "walk_id": "3_archwalk",
        "node_name": "ArcherCharacter",
    },
    {
        "filename": "GoblinCharacter.tscn",
        "scene_uid": 'uid="uid://c6goblin1char"',
        "script_path": "res://scripts/characters/enemies/goblin_character.gd",
        "script_id": "1_goblin",
        "idle_path": "res://assets/sprites/characters/goblin_idle.png",
        "idle_uid": 'uid="uid://wobf3ct7hyil"',
        "idle_id": "2_gobspr",
        "walk_path": "res://assets/sprites/characters/goblin_walk.png",
        "walk_id": "3_gobwalk",
        "node_name": "GoblinCharacter",
    },
    {
        "filename": "EnemyCharacter.tscn",
        "scene_uid": 'uid="uid://c5enemy1char1"',
        "script_path": "res://scripts/characters/enemies/enemy_character.gd",
        "script_id": "1_enemy",
        "idle_path": "res://assets/test/World of Solaria Demo Pack Update 04/16x16/Sprites/New/Chris Idle.png",
        "idle_uid": 'uid="uid://btwjvapwp0t8w"',
        "idle_id": "2_uqqyt",
        "walk_path": "res://assets/test/World of Solaria Demo Pack Update 04/16x16/Sprites/New/Chris Walk.png",
        "walk_id": "3_walk",
        "node_name": "EnemyCharacter",
    },
]

DIRECTIONS = ["up", "down", "left", "right"]


def generate_tscn(cfg):
    lines = []

    # Header — 3 ext_resources + 48 atlas textures + 1 SpriteFrames = 52 load_steps
    lines.append(f'[gd_scene load_steps=52 format=3 {cfg["scene_uid"]}]')
    lines.append("")
    lines.append(f'[ext_resource type="Script" path="{cfg["script_path"]}" id="{cfg["script_id"]}"]')
    lines.append(f'[ext_resource type="Texture2D" {cfg["idle_uid"]} path="{cfg["idle_path"]}" id="{cfg["idle_id"]}"]')
    lines.append(f'[ext_resource type="Texture2D" path="{cfg["walk_path"]}" id="{cfg["walk_id"]}"]')
    lines.append("")

    # Atlas textures for idle (4 rows × 6 cols)
    idle_ids = {}
    for row_idx, d in enumerate(DIRECTIONS):
        idle_ids[d] = []
        for col in range(6):
            sub_id = f"idle_{d}_{col}"
            lines.append(f'[sub_resource type="AtlasTexture" id="{sub_id}"]')
            lines.append(f'atlas = ExtResource("{cfg["idle_id"]}")')
            lines.append(f"region = Rect2({col * 80}, {row_idx * 80}, 80, 80)")
            lines.append("")
            idle_ids[d].append(sub_id)

    # Atlas textures for walk (4 rows × 6 cols)
    walk_ids = {}
    for row_idx, d in enumerate(DIRECTIONS):
        walk_ids[d] = []
        for col in range(6):
            sub_id = f"walk_{d}_{col}"
            lines.append(f'[sub_resource type="AtlasTexture" id="{sub_id}"]')
            lines.append(f'atlas = ExtResource("{cfg["walk_id"]}")')
            lines.append(f"region = Rect2({col * 80}, {row_idx * 80}, 80, 80)")
            lines.append("")
            walk_ids[d].append(sub_id)

    # SpriteFrames with 8 animations
    anim_entries = []
    for d in DIRECTIONS:
        for prefix, id_map in [("idle", idle_ids), ("walk", walk_ids)]:
            frames = ", ".join(
                '{\n"duration": 1.0,\n"texture": SubResource("' + fid + '")\n}'
                for fid in id_map[d]
            )
            anim_entries.append(
                '{\n"frames": [' + frames + '],\n"loop": true,\n"name": &"'
                + prefix + "_" + d + '",\n"speed": 10.0\n}'
            )

    lines.append('[sub_resource type="SpriteFrames" id="SpriteFrames_all"]')
    lines.append("animations = [" + ", ".join(anim_entries) + "]")
    lines.append("")

    # Nodes
    lines.append(f'[node name="{cfg["node_name"]}" type="Node2D"]')
    lines.append("z_index = 100")
    lines.append(f'script = ExtResource("{cfg["script_id"]}")')
    lines.append("")
    lines.append('[node name="AnimatedSprite2D" type="AnimatedSprite2D" parent="."]')
    lines.append('sprite_frames = SubResource("SpriteFrames_all")')
    lines.append('autoplay = "idle_down"')
    lines.append("")

    return "\n".join(lines)


def main():
    for cfg in CHARACTERS:
        content = generate_tscn(cfg)
        out_path = SCENES / cfg["filename"]
        out_path.write_text(content, newline="\n")
        print(f"Generated {out_path.name}")


if __name__ == "__main__":
    main()
