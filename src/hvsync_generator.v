/*
 * hvsync_generator.v
 */
`default_nettype none

module hvsync_generator(
  input wire clk,
  input wire reset,
  output reg hsync,
  output reg vsync,
  output reg display_on,
  output reg [9:0] hpos,
  output reg [9:0] vpos
);

  // 640x480 @ 60Hz timing constants (assuming 25MHz clock)
  parameter H_DISPLAY       = 640;
  parameter H_FRONT_PORCH   = 16;
  parameter H_SYNC_PULSE    = 96;
  parameter H_BACK_PORCH    = 48;
  parameter H_MAX           = H_DISPLAY + H_FRONT_PORCH + H_SYNC_PULSE + H_BACK_PORCH - 1;
  parameter H_SYNC_START    = H_DISPLAY + H_FRONT_PORCH;
  parameter H_SYNC_END      = H_DISPLAY + H_FRONT_PORCH + H_SYNC_PULSE - 1;

  parameter V_DISPLAY       = 480;
  parameter V_FRONT_PORCH   = 10;
  parameter V_SYNC_PULSE    = 2;
  parameter V_BACK_PORCH    = 33;
  parameter V_MAX           = V_DISPLAY + V_FRONT_PORCH + V_SYNC_PULSE + V_BACK_PORCH - 1;
  parameter V_SYNC_START    = V_DISPLAY + V_FRONT_PORCH;
  parameter V_SYNC_END      = V_DISPLAY + V_FRONT_PORCH + V_SYNC_PULSE - 1;

  wire hmaxxed = (hpos == H_MAX);
  wire vmaxxed = (vpos == V_MAX);

  always @(posedge clk) begin
    if (reset) begin
      hpos <= 0;
      vpos <= 0;
      hsync <= 0;
      vsync <= 0;
      display_on <= 0;
    end else begin
      if (hmaxxed)
        hpos <= 0;
      else
        hpos <= hpos + 1;

      if (hmaxxed) begin
        if (vmaxxed)
          vpos <= 0;
        else
          vpos <= vpos + 1;
      end

      hsync <= (hpos >= H_SYNC_START && hpos <= H_SYNC_END);
      vsync <= (vpos >= V_SYNC_START && vpos <= V_SYNC_END);

      display_on <= (hpos < H_DISPLAY) && (vpos < V_DISPLAY);
    end
  end

endmodule
