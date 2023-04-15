#[compute]
#version 450
// thanks to https://github.com/OverloadedOrama/Godot-ComputeShader-GameOfLife/blob/main/gol.glsl
// and https://github.com/yumcyaWiz/glsl-compute-shader-sandbox/blob/main/sandbox/life-game/shaders/update-cells.comp

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(set = 0, binding = 0, rgba32f) uniform image3D cells_in;
layout(set = 0, binding = 1, rgba32f) uniform image3D cells_out;

uint updateCell(ivec3 cell_idx) {
	float cell_status = imageLoad(cells_in, cell_idx).x;;

	float alive_cells = 0.0;
	alive_cells += imageLoad(cells_in, cell_idx + ivec3(-1,0,0)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec3(-1,-1,0)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec3(-1,1,0)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec3(1,0,0)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec3(1,-1,0)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec3(1,1,0)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec3(0,-1,0)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec3(0,-1,-1)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec3(0,-1,1)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec3(0,1,0)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec3(0,1,-1)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec3(0,1,1)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec3(0,0,-1)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec3(-1,0,-1)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec3(1,0,-1)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec3(0,0,1)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec3(-1,0,1)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec3(1,0,1)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec3(-1,-1,-1)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec3(1,-1,-1)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec3(-1,1,-1)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec3(1,1,-1)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec3(-1,1,1)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec3(1,1,1)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec3(-1,-1,1)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec3(1,-1,1)).x;

	return uint(cell_status < 0.5 && alive_cells == 5.0) + uint(cell_status >= 0.5 && alive_cells > 3.5 && alive_cells < 5.5);
}

void main() {
	ivec3 cell_loc = ivec3(gl_GlobalInvocationID.xyz);
	uint next_status = updateCell(cell_loc);
	imageStore(cells_out, cell_loc, uvec4(uvec3(next_status), 1));
}