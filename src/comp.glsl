#[compute]
#version 450
// thanks to https://github.com/OverloadedOrama/Godot-ComputeShader-GameOfLife/blob/main/gol.glsl
// and https://github.com/yumcyaWiz/glsl-compute-shader-sandbox/blob/main/sandbox/life-game/shaders/update-cells.comp

layout(local_size_x = 3, local_size_y = 3, local_size_z = 3) in;

// speed it up by making layout size 3x3x3

layout(set = 0, binding = 0, std430) restrict buffer InputBuffer {
    float data[];
}
input_buffer;
layout(set = 0, binding = 1, std430) restrict buffer OutputBuffer {
    float data[];
}
output_buffer;
layout(set = 0, binding = 2, std430) restrict buffer ParamBuffer {
    float data[];
}
param_buffer;

shared int total;


float getNewValue(ivec3 cell_pos) {
	total = 0;
	
	float p2 = param_buffer.data[2];
	float p1 = param_buffer.data[1] + 0.5;
	float p0 = param_buffer.data[0] - 0.5;
	
	uint cellIndex = ((cell_pos.x * gl_NumWorkGroups.x * gl_NumWorkGroups.x) + (cell_pos.y * gl_NumWorkGroups.x) + (cell_pos.z));
	float cellVal = input_buffer.data[cellIndex];
	
	ivec3 neighbor_offset = ivec3(gl_LocalInvocationID) - ivec3(1,1,1);
	ivec3 sample_pos = cell_pos + neighbor_offset;
	uint sampleIndex = ((sample_pos.x * gl_NumWorkGroups.x * gl_NumWorkGroups.x) + (sample_pos.y * gl_NumWorkGroups.x) + (sample_pos.z));
	
	memoryBarrier();
	
	sampleIndex = max(sampleIndex, 0);
	sampleIndex = min(sampleIndex, gl_NumWorkGroups.x * gl_NumWorkGroups.x * gl_NumWorkGroups.x);
	float sampleVal = input_buffer.data[sampleIndex];
	atomicAdd(total, int(sampleVal));
	
	memoryBarrier();
	
	total -= int(cellVal);
	
	float result = float(cellVal < 0.5 && float(total) == p2) + float(cellVal >= 0.5 && float(total) > p0 && float(total) < p1);
	
	output_buffer.data[cellIndex] = result;
	
	return result;
}


// uint updateCell(ivec2 cell_idx) {
	// float cell_status = imageLoad(cells_in, cell_idx).x;
// //	ivec3 neighbor_offset = ivec3(gl_LocalInvocationID) - ivec3(1,1,1);
// //	ivec2 neighbor_loc = ivec2((gl_GlobalInvocationID.x + neighbor_offset.x) + ((gl_GlobalInvocationID.z + neighbor_offset.z) * gl_NumWorkGroups.x), gl_GlobalInvocationID.y + neighbor_offset.y);
// //	float neighbor_status = imageLoad(cells_in, neighbor_loc).x;
// //	uint location = ((gl_WorkGroupID.x * gl_NumWorkGroups.x * gl_NumWorkGroups.x) + (gl_WorkGroupID.y * gl_NumWorkGroups.x) + (gl_WorkGroupID.z));
// //	atomicAdd(my_3D_buffer.data[location], int(neighbor_status));
	
	// int wgsize = int(gl_NumWorkGroups.x);

	// float p2 = my_data_buffer.data[2];
	// float p1 = my_data_buffer.data[1] + 0.5;
	// float p0 = my_data_buffer.data[0] - 0.5;

	// float alive_cells = 0.0;
	
// //	ivec2 offset = ivec2(neighbor_offset.x + (wgsize * neighbor_offset.z), neighbor_offset.y);
	
// //	int neighbor_val = int(imageLoad(cells_in, cell_idx + offset).x);
	
// //	syncronize();
	
// //	atomicAdd(my_3D_buffer.data[location], neighbor_val);
	
// //	atomicAdd(alive_cells, neighbor_val);
// //	alive_cells += imageLoad(cells_in, cell_idx + offset).x;
	
	// alive_cells += imageLoad(cells_in, cell_idx + ivec2(-1,0)).x;
	// alive_cells += imageLoad(cells_in, cell_idx + ivec2(-1,-1)).x;
	// alive_cells += imageLoad(cells_in, cell_idx + ivec2(-1,1)).x;
	// alive_cells += imageLoad(cells_in, cell_idx + ivec2(1,0)).x;
	// alive_cells += imageLoad(cells_in, cell_idx + ivec2(1,-1)).x;
	// alive_cells += imageLoad(cells_in, cell_idx + ivec2(1,1)).x;
	// alive_cells += imageLoad(cells_in, cell_idx + ivec2(0,-1)).x;
	// alive_cells += imageLoad(cells_in, cell_idx + ivec2(0-wgsize,-1)).x;
	// alive_cells += imageLoad(cells_in, cell_idx + ivec2(0+wgsize,-1)).x;
	// alive_cells += imageLoad(cells_in, cell_idx + ivec2(0,1)).x;
	// alive_cells += imageLoad(cells_in, cell_idx + ivec2(0-wgsize,1)).x;
	// alive_cells += imageLoad(cells_in, cell_idx + ivec2(0+wgsize,1)).x;
	// alive_cells += imageLoad(cells_in, cell_idx + ivec2(0-wgsize,0)).x;
	// alive_cells += imageLoad(cells_in, cell_idx + ivec2(-1-wgsize,0)).x;
	// alive_cells += imageLoad(cells_in, cell_idx + ivec2(1-wgsize,0)).x;
	// alive_cells += imageLoad(cells_in, cell_idx + ivec2(0+wgsize,0)).x;
	// alive_cells += imageLoad(cells_in, cell_idx + ivec2(-1+wgsize,0)).x;
	// alive_cells += imageLoad(cells_in, cell_idx + ivec2(1+wgsize,0)).x;
	// alive_cells += imageLoad(cells_in, cell_idx + ivec2(-1-wgsize,-1)).x;
	// alive_cells += imageLoad(cells_in, cell_idx + ivec2(1-wgsize,-1)).x;
	// alive_cells += imageLoad(cells_in, cell_idx + ivec2(-1-wgsize,1)).x;
	// alive_cells += imageLoad(cells_in, cell_idx + ivec2(1-wgsize,1)).x;
	// alive_cells += imageLoad(cells_in, cell_idx + ivec2(-1+wgsize,1)).x;
	// alive_cells += imageLoad(cells_in, cell_idx + ivec2(1+wgsize,1)).x;
	// alive_cells += imageLoad(cells_in, cell_idx + ivec2(-1+wgsize,-1)).x;
	// alive_cells += imageLoad(cells_in, cell_idx + ivec2(1+wgsize,-1)).x;

// //	syncronize();

	// return uint(cell_status < 0.5 && alive_cells == p2) + uint(cell_status >= 0.5 && alive_cells > p0 && alive_cells < p1);
// }


void main() {
	float newVal = getNewValue(ivec3(gl_WorkGroupID));
	//ivec2 cell_loc = ivec2(gl_GlobalInvocationID.x + (gl_GlobalInvocationID.z * gl_NumWorkGroups.x), gl_GlobalInvocationID.y);
	//uint next_status = updateCell(cell_loc);
	//imageStore(cells_out, cell_loc, uvec4(uvec3(next_status), 1));
	//uint next_status = checkCell3D(ivec3(gl_WorkGroupID));
	//imageStore(img3d_out, ivec3(gl_WorkGroupID), uvec4(uvec3(next_status), 1));
}