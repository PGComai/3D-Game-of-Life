#[compute]
#version 450
// thanks to https://github.com/OverloadedOrama/Godot-ComputeShader-GameOfLife/blob/main/gol.glsl
// and https://github.com/yumcyaWiz/glsl-compute-shader-sandbox/blob/main/sandbox/life-game/shaders/update-cells.comp

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

// speed it up by making layout size 3x3x3

layout(set = 0, binding = 0, rgba32f) uniform image2D cells_in;
layout(set = 0, binding = 1, rgba32f) uniform image2D cells_out;
layout(set = 0, binding = 2, std430) restrict buffer MyDataBuffer {
    float data[];
}
my_data_buffer;
//layout(set = 0, binding = 3) uniform sampler3D img3d;
//layout(set = 0, binding = 4, r8) uniform image3D img3d_out;
layout(set = 0, binding = 3, std430) restrict buffer My3DBuffer {
    int data[];
}
my_3D_buffer;

//shared int alive_cells;

//void syncronize()
//{
//	memoryBarrierShared();
//	barrier();
//}

uint updateCell(ivec2 cell_idx) {
	float cell_status = imageLoad(cells_in, cell_idx).x;
//	ivec3 neighbor_offset = ivec3(gl_LocalInvocationID) - ivec3(1,1,1);
//	ivec2 neighbor_loc = ivec2((gl_GlobalInvocationID.x + neighbor_offset.x) + ((gl_GlobalInvocationID.z + neighbor_offset.z) * gl_NumWorkGroups.x), gl_GlobalInvocationID.y + neighbor_offset.y);
//	float neighbor_status = imageLoad(cells_in, neighbor_loc).x;
//	uint location = ((gl_WorkGroupID.x * gl_NumWorkGroups.x * gl_NumWorkGroups.x) + (gl_WorkGroupID.y * gl_NumWorkGroups.x) + (gl_WorkGroupID.z));
//	atomicAdd(my_3D_buffer.data[location], int(neighbor_status));
	
	int wgsize = int(gl_NumWorkGroups.x);

	float p2 = my_data_buffer.data[2];
	float p1 = my_data_buffer.data[1] + 0.5;
	float p0 = my_data_buffer.data[0] - 0.5;

	float alive_cells = 0.0;
	
//	ivec2 offset = ivec2(neighbor_offset.x + (wgsize * neighbor_offset.z), neighbor_offset.y);
	
//	int neighbor_val = int(imageLoad(cells_in, cell_idx + offset).x);
	
//	syncronize();
	
//	atomicAdd(my_3D_buffer.data[location], neighbor_val);
	
//	atomicAdd(alive_cells, neighbor_val);
//	alive_cells += imageLoad(cells_in, cell_idx + offset).x;
	
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

//	syncronize();

	return uint(cell_status < 0.5 && alive_cells == p2) + uint(cell_status >= 0.5 && alive_cells > p0 && alive_cells < p1);
}

//uint checkCell3D(ivec3 cell_loc) {
//	vec4 tex = texture(img3d, cell_loc);
//	vec4 tex_neighbor = texture(img3d, ivec3(gl_GlobalInvocationID));
//	float p2 = my_data_buffer.data[2];
//	float p1 = my_data_buffer.data[1] + 0.5;
//	float p0 = my_data_buffer.data[0] - 0.5;
//	uint location = ((gl_WorkGroupID.x * gl_NumWorkGroups.x * gl_NumWorkGroups.x) + (gl_WorkGroupID.y * gl_NumWorkGroups.x) + (gl_WorkGroupID.z));
//	float cell_status = tex.x;
//	float neighbor_status = tex_neighbor.x;
//	atomicAdd(my_3D_buffer.data[location], int(neighbor_status));
//	float alive_cells = float(max(my_3D_buffer.data[location] - int(cell_status), 0));
//	return uint(cell_status < 0.5 && alive_cells == p2) + uint(cell_status >= 0.5 && alive_cells > p0 && alive_cells < p1);
//} 

void main() {
	ivec2 cell_loc = ivec2(gl_GlobalInvocationID.x + (gl_GlobalInvocationID.z * gl_NumWorkGroups.x), gl_GlobalInvocationID.y);
	uint next_status = updateCell(cell_loc);
	imageStore(cells_out, cell_loc, uvec4(uvec3(next_status), 1));
	//uint next_status = checkCell3D(ivec3(gl_WorkGroupID));
	//imageStore(img3d_out, ivec3(gl_WorkGroupID), uvec4(uvec3(next_status), 1));
}