#[compute]
#version 450
// https://github.com/OverloadedOrama/Godot-ComputeShader-GameOfLife/blob/main/gol.glsl

// Taken and modifier from https://github.com/yumcyaWiz/glsl-compute-shader-sandbox/blob/main/sandbox/life-game/shaders/update-cells.comp

// 8x8 grid of invocations
layout(local_size_x = 8, local_size_y = 8) in;

// not sure what this does, something about establishing variables
layout(set = 0, binding = 0, rgba32f) uniform image2D cells_in;
layout(set = 0, binding = 1, rgba32f) uniform image2D cells_out;

// gol function
uint updateCell(ivec2 cell_idx) {
  // imageLoad grabs a texel from the specified image texture
  float current_status = imageLoad(cells_in, cell_idx).x;

  // counts number of living cells around our cell
  float alive_cells = 0.0;
  alive_cells += imageLoad(cells_in, cell_idx + ivec2(-1, -1)).x;
  alive_cells += imageLoad(cells_in, cell_idx + ivec2(-1, 0)).x;
  alive_cells += imageLoad(cells_in, cell_idx + ivec2(-1, 1)).x;
  alive_cells += imageLoad(cells_in, cell_idx + ivec2(0, -1)).x;
  alive_cells += imageLoad(cells_in, cell_idx + ivec2(0, 1)).x;
  alive_cells += imageLoad(cells_in, cell_idx + ivec2(1, -1)).x;
  alive_cells += imageLoad(cells_in, cell_idx + ivec2(1, 0)).x;
  alive_cells += imageLoad(cells_in, cell_idx + ivec2(1, 1)).x;

  // test bools to create either 1 or 0 result
  //              cell is dead and surrounded by 3 living cells = 1                      cell is alive and surrounded by 2 to 3 living cells = 1
  return uint(current_status < 0.5 && alive_cells > 2.5 && alive_cells < 3.5) + uint(current_status >= 0.5 && alive_cells > 1.5 && alive_cells < 3.5);
}

// main function
void main() {
  // gidx is the location of the cell which corresponds to the workgroup it is assigned to (same shape?)
  ivec2 gidx = ivec2(gl_GlobalInvocationID.xy);
  // call gol function with cell location as argument, get new value
  uint next_status = updateCell(gidx);
  // store results for return to cpu
  imageStore(cells_out, gidx, uvec4(uvec3(next_status), 1));
}