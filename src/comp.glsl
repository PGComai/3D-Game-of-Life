#[compute]
#version 450
// thanks to https://github.com/OverloadedOrama/Godot-ComputeShader-GameOfLife/blob/main/gol.glsl
// and https://github.com/yumcyaWiz/glsl-compute-shader-sandbox/blob/main/sandbox/life-game/shaders/update-cells.comp

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(set = 0, binding = 0, rgba32f) uniform image2D cells_in;
layout(set = 0, binding = 1, rgba32f) uniform image2D cells_out;
layout(set = 0, binding = 2, std430) restrict buffer MyDataBuffer {
    float data[];
}
my_data_buffer;

uint updateCell(ivec2 cell_idx) {
	float cell_status = imageLoad(cells_in, cell_idx).x;

	int wgsize = int(gl_NumWorkGroups.x);

	float p2 = my_data_buffer.data[2];
	float p1 = my_data_buffer.data[1] + 0.5;
	float p0 = my_data_buffer.data[0] - 0.5;

	float alive_cells = 0.0;
	alive_cells += imageLoad(cells_in, cell_idx + ivec2(-1,0)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec2(-1,-1)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec2(-1,1)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec2(1,0)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec2(1,-1)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec2(1,1)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec2(0,-1)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec2(0-wgsize,-1)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec2(0+wgsize,-1)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec2(0,1)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec2(0-wgsize,1)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec2(0+wgsize,1)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec2(0-wgsize,0)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec2(-1-wgsize,0)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec2(1-wgsize,0)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec2(0+wgsize,0)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec2(-1+wgsize,0)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec2(1+wgsize,0)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec2(-1-wgsize,-1)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec2(1-wgsize,-1)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec2(-1-wgsize,1)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec2(1-wgsize,1)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec2(-1+wgsize,1)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec2(1+wgsize,1)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec2(-1+wgsize,-1)).x;
	alive_cells += imageLoad(cells_in, cell_idx + ivec2(1+wgsize,-1)).x;

	return uint(cell_status < 0.5 && alive_cells == p2) + uint(cell_status >= 0.5 && alive_cells > p0 && alive_cells < p1);
}

void main() {
	ivec2 cell_loc = ivec2(gl_GlobalInvocationID.x + (gl_GlobalInvocationID.z * gl_NumWorkGroups.x), gl_GlobalInvocationID.y);
	uint next_status = updateCell(cell_loc);
	imageStore(cells_out, cell_loc, uvec4(uvec3(next_status), 1));
}