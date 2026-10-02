/*
 * THE PROCEDURAL UNIVERSE: 300 LINES OF PURE MATH
 * Zero Memory (No LUTs) - Pure Combinatorial SDFs
 * Features: Running Dog, Parallax Mountains, Trees, Sun, Clouds, Birds!
 */

`default_nettype none

module tt_um_vga_example(
  input  wire [7:0] ui_in,    
  output wire [7:0] uo_out,   
  input  wire [7:0] uio_in,   
  output wire [7:0] uio_out,  
  output wire [7:0] uio_oe,   
  input  wire       ena,      
  input  wire       clk,      
  input  wire       rst_n     
);

  wire hsync, vsync, video_active;
  wire [9:0] pix_x, pix_y;
  wire [1:0] R_vga, G_vga, B_vga;

  assign uo_out = {hsync, B_vga[0], G_vga[0], R_vga[0], vsync, B_vga[1], G_vga[1], R_vga[1]};
  assign uio_out = 8'b0;
  assign uio_oe  = 8'b0;
  wire _unused_ok = &{ena, ui_in, uio_in};

  reg [15:0] frame_counter;

  hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(pix_x),
    .vpos(pix_y)
  );

  always @(posedge vsync, negedge rst_n) begin
    if (~rst_n) frame_counter <= 0;
    else frame_counter <= frame_counter + 1;
  end

  // =====================================================================
  // 1. GLOBAL COORDINATES & ANIMATIONS
  // =====================================================================
  wire signed [11:0] cx = $signed({2'b00, pix_x}) - 12'sd320;
  wire signed [11:0] cy = $signed({2'b00, pix_y}) - 12'sd240;

  // Dog animation waves
  wire signed [9:0] swing = $signed({5'b0, (frame_counter[5] ? ~frame_counter[4:0] : frame_counter[4:0])}) - 10'sd16;
  wire signed [9:0] tail_swing = $signed({7'b0, (frame_counter[3] ? ~frame_counter[2:0] : frame_counter[2:0])}) - 10'sd4;
  wire signed [9:0] pant = tail_swing / 2; 

  // Global scrolling offsets (parallax)
  wire signed [11:0] scroll_fast = $signed({2'b00, frame_counter[9:0]});
  wire signed [11:0] scroll_med  = $signed({2'b00, frame_counter[10:1]});
  wire signed [11:0] scroll_slow = $signed({2'b00, frame_counter[11:2]});

  // =====================================================================
  // 2. SUN AND SKY
  // =====================================================================
  wire signed [11:0] sun_dx = cx - 12'sd150; 
  wire signed [11:0] sun_dy = cy + 12'sd150;
  wire signed [11:0] asun_dx = (sun_dx < 12'sd0) ? -sun_dx : sun_dx;
  wire signed [11:0] asun_dy = (sun_dy < 12'sd0) ? -sun_dy : sun_dy;
  
  // Sun core
  wire sun_core = (asun_dx < 12'sd25) && (asun_dy < 12'sd25);
  // Sun corona (aura)
  wire sun_aura = (asun_dx < 12'sd35) && (asun_dy < 12'sd35);

  // =====================================================================
  // 3. SCROLLING MOUNTAINS
  // =====================================================================
  // Mountain 1 (Background)
  wire signed [11:0] m1_x = cx + scroll_slow;
  // Modulo 256 for repeating mountains
  wire signed [11:0] m1_mod = (m1_x & 12'sd255) - 12'sd128;
  wire signed [11:0] am1_x = (m1_mod < 12'sd0) ? -m1_mod : m1_mod;
  // Mountain height profile (triangle)
  wire signed [11:0] m1_h = 12'sd100 - am1_x;
  wire mount1 = (cy > -m1_h) && (cy < 12'sd40);

  // Mountain 2 (Foreground)
  wire signed [11:0] m2_x = cx + scroll_med + 12'sd64;
  wire signed [11:0] m2_mod = (m2_x & 12'sd511) - 12'sd256;
  wire signed [11:0] am2_x = (m2_mod < 12'sd0) ? -m2_mod : m2_mod;
  wire signed [11:0] m2_h = 12'sd50 - (am2_x / 2);
  wire mount2 = (cy > -m2_h) && (cy < 12'sd40);

  // =====================================================================
  // 4. CLOUDS
  // =====================================================================
  wire signed [11:0] c1_x = m1_x - 12'sd100;
  wire signed [11:0] ac1_x = (c1_x < 12'sd0) ? -c1_x : c1_x;
  wire cloud1 = (ac1_x < 12'sd40) && (cy > -12'sd150) && (cy < -12'sd120);
  
  wire signed [11:0] c2_x = m1_x + 12'sd80;
  wire signed [11:0] ac2_x = (c2_x < 12'sd0) ? -c2_x : c2_x;
  wire cloud2 = (ac2_x < 12'sd30) && (cy > -12'sd180) && (cy < -12'sd160);

  wire cloud = cloud1 | cloud2;

  // =====================================================================
  // 5. BIRDS FLOCK
  // =====================================================================
  // Bird wing animation (flap)
  wire signed [11:0] flap = tail_swing;
  
  wire signed [11:0] cx_med = cx - scroll_med;
  wire signed [11:0] bd_x = cx_med + 12'sd100;
  wire signed [11:0] abd_x = (bd_x < 12'sd0) ? -bd_x : bd_x;
  wire signed [11:0] bd_y = cy + 12'sd80;
  // V shape: y = abs(x) / 2 + flap
  wire signed [11:0] v_shape = (abd_x / 2) + flap;
  wire bird1 = (abd_x < 12'sd10) && (bd_y > v_shape) && (bd_y < v_shape + 12'sd3);

  wire signed [11:0] bd2_x = cx_med + 12'sd130;
  wire signed [11:0] abd2_x = (bd2_x < 12'sd0) ? -bd2_x : bd2_x;
  wire signed [11:0] bd2_y = cy + 12'sd90;
  wire signed [11:0] v2_shape = (abd2_x / 2) + flap;
  wire bird2 = (abd2_x < 12'sd8) && (bd2_y > v2_shape) && (bd2_y < v2_shape + 12'sd3);

  wire bird = bird1 | bird2;

  // =====================================================================
  // 6. SCROLLING TREES
  // =====================================================================
  wire signed [11:0] tr_x = cx + scroll_fast;
  wire signed [11:0] tr_mod = (tr_x & 12'sd255) - 12'sd128;
  wire signed [11:0] atr_x = (tr_mod < 12'sd0) ? -tr_mod : tr_mod;
  
  // Trunk
  wire tree_trunk = (atr_x < 12'sd4) && (cy > -12'sd20) && (cy < 12'sd40);
  
  // Leaves
  wire signed [11:0] lf_y = cy + 12'sd30;
  wire signed [11:0] alf_y = (lf_y < 12'sd0) ? -lf_y : lf_y;
  wire tree_leaves = (atr_x < 12'sd25) && (alf_y < 12'sd35);
  
  wire tree = tree_trunk | tree_leaves;

  // =====================================================================
  // 7. THE DOG (Detailed SDFs)
  // =====================================================================
  wire signed [9:0] dog_cx = $signed(cx[9:0]);
  wire signed [9:0] dog_cy = $signed(cy[9:0]);
  // HEAD
  wire signed [9:0] h_dx = dog_cx - 10'sd30; wire signed [9:0] h_dy = dog_cy + 10'sd40;
  wire signed [9:0] ah_dx = (h_dx < 10'sd0) ? -h_dx : h_dx;
  wire signed [9:0] ah_dy = (h_dy < 10'sd0) ? -h_dy : h_dy;
  wire head = (ah_dx < 10'sd20) && (ah_dy < 10'sd20);

  // SNOUT
  wire signed [9:0] sn_dx = dog_cx - 10'sd52; wire signed [9:0] sn_dy = dog_cy + 10'sd28;
  wire signed [9:0] asn_dx = (sn_dx < 10'sd0) ? -sn_dx : sn_dx;
  wire signed [9:0] asn_dy = (sn_dy < 10'sd0) ? -sn_dy : sn_dy;
  wire snout = (asn_dx < 10'sd14) && (asn_dy < 10'sd10);

  // NOSE
  wire signed [9:0] n_dx = dog_cx - 10'sd65; wire signed [9:0] n_dy = dog_cy + 10'sd32;
  wire signed [9:0] an_dx = (n_dx < 10'sd0) ? -n_dx : n_dx;
  wire signed [9:0] an_dy = (n_dy < 10'sd0) ? -n_dy : n_dy;
  wire nose = (an_dx < 10'sd4) && (an_dy < 10'sd4);

  // EYE & PUPIL
  wire signed [9:0] e_dx = dog_cx - 10'sd35; wire signed [9:0] e_dy = dog_cy + 10'sd45;
  wire signed [9:0] ae_dx = (e_dx < 10'sd0) ? -e_dx : e_dx;
  wire signed [9:0] ae_dy = (e_dy < 10'sd0) ? -e_dy : e_dy;
  wire eye = (ae_dx < 10'sd3) && (ae_dy < 10'sd4);
  wire pupil = eye && (dog_cx > 10'sd34) && (dog_cy < -10'sd44);

  // EAR
  wire signed [9:0] ea_dx = dog_cx - 10'sd15; wire signed [9:0] ea_dy = dog_cy + 10'sd35;
  wire signed [9:0] aea_dx = (ea_dx < 10'sd0) ? -ea_dx : ea_dx;
  wire signed [9:0] aea_dy = (ea_dy < 10'sd0) ? -ea_dy : ea_dy;
  wire ear = (aea_dx < 10'sd8) && (aea_dy < 10'sd16);

  // COLLAR & TAG
  wire signed [9:0] col_dx = dog_cx - 10'sd15; wire signed [9:0] col_dy = dog_cy + 10'sd15;
  wire signed [9:0] acol_dx = (col_dx < 10'sd0) ? -col_dx : col_dx;
  wire signed [9:0] acol_dy = (col_dy < 10'sd0) ? -col_dy : col_dy;
  wire collar = (acol_dx < 10'sd12) && (acol_dy < 10'sd6);
  wire tag = (acol_dx < 10'sd4) && (col_dy > 10'sd2) && (col_dy < 10'sd8); 

  // TONGUE
  wire signed [9:0] to_dx = dog_cx - 10'sd55; wire signed [9:0] to_dy = dog_cy + 10'sd18 + pant;
  wire signed [9:0] ato_dx = (to_dx < 10'sd0) ? -to_dx : to_dx;
  wire signed [9:0] ato_dy = (to_dy < 10'sd0) ? -to_dy : to_dy;
  wire tongue = (ato_dx < 10'sd5) && (ato_dy < 10'sd8);

  // BODY & BELLY
  wire signed [9:0] b_dx = dog_cx + 10'sd15; wire signed [9:0] b_dy = dog_cy + 10'sd5;
  wire signed [9:0] ab_dx = (b_dx < 10'sd0) ? -b_dx : b_dx;
  wire signed [9:0] ab_dy = (b_dy < 10'sd0) ? -b_dy : b_dy;
  wire body = (ab_dx < 10'sd40) && (ab_dy < 10'sd18);
  wire belly = body && (dog_cy > 10'sd12); 

  // LEGS & PAWS
  wire signed [9:0] fl_y = dog_cy - 10'sd10;
  wire signed [9:0] fl_x = dog_cx - 10'sd10 - swing;
  wire signed [9:0] afl_x = (fl_x < 10'sd0) ? -fl_x : fl_x;
  wire f_leg = (afl_x < 10'sd6) && (fl_y > 10'sd0) && (fl_y < 10'sd25);
  wire f_paw = (afl_x < 10'sd8) && (fl_y > 10'sd20) && (fl_y < 10'sd25) && (fl_x > -10'sd2); 

  wire signed [9:0] fl2_x = dog_cx - 10'sd5 + swing;
  wire signed [9:0] afl2_x = (fl2_x < 10'sd0) ? -fl2_x : fl2_x;
  wire f_leg2 = (afl2_x < 10'sd6) && (fl_y > 10'sd0) && (fl_y < 10'sd22);
  wire f_paw2 = (afl2_x < 10'sd8) && (fl_y > 10'sd17) && (fl_y < 10'sd22) && (fl2_x > -10'sd2);

  wire signed [9:0] bl_y = dog_cy - 10'sd10;
  wire signed [9:0] bl_x = dog_cx + 10'sd35 + swing;
  wire signed [9:0] abl_x = (bl_x < 10'sd0) ? -bl_x : bl_x;
  wire b_leg = (abl_x < 10'sd7) && (bl_y > 10'sd0) && (bl_y < 10'sd25);
  wire b_paw = (abl_x < 10'sd9) && (bl_y > 10'sd20) && (bl_y < 10'sd25) && (bl_x > -10'sd2);

  wire signed [9:0] bl2_x = dog_cx + 10'sd45 - swing;
  wire signed [9:0] abl2_x = (bl2_x < 10'sd0) ? -bl2_x : bl2_x;
  wire b_leg2 = (abl2_x < 10'sd7) && (bl_y > 10'sd0) && (bl_y < 10'sd22);
  wire b_paw2 = (abl2_x < 10'sd9) && (bl_y > 10'sd17) && (bl_y < 10'sd22) && (bl2_x > -10'sd2);

  // TAIL
  wire signed [9:0] ty = dog_cy + 10'sd15;
  wire signed [9:0] tx = dog_cx + 10'sd55 - tail_swing;
  wire signed [9:0] atx = (tx < 10'sd0) ? -tx : tx;
  wire tail = (atx < 10'sd5) && (ty < 10'sd0) && (ty > -10'sd25);

  // =====================================================================
  // 8. COLOR COMPOSITION & FORMATTED MULTIPLEXER (Fixes line limits)
  // =====================================================================
  
  // Dog components combined
  wire is_dog_main = head | snout | (body & ~belly) | f_leg | f_paw | b_leg | b_paw | tail;
  wire is_dog_white = belly;
  wire is_dog_dark = f_leg2 | f_paw2 | b_leg2 | b_paw2 | ear; 

  // Ground and Grass
  wire is_ground = (cy > 12'sd30);
  wire grass_pattern = (((cx + scroll_fast) & 12'sd32) == 12'sd0) ^ ((cy & 12'sd16) == 12'sd0);
  
  // Background palette
  reg [1:0] bg_R, bg_G, bg_B;
  always @(*) begin
    if (is_ground) begin
      bg_R = 2'b00;
      bg_G = grass_pattern ? 2'b10 : 2'b11;
      bg_B = 2'b00;
    end else if (tree) begin
      bg_R = tree_trunk ? 2'b01 : 2'b00;
      bg_G = tree_trunk ? 2'b01 : 2'b10;
      bg_B = 2'b00;
    end else if (mount2) begin
      bg_R = 2'b01; bg_G = 2'b01; bg_B = 2'b01; // Dark Gray
    end else if (mount1) begin
      bg_R = 2'b10; bg_G = 2'b10; bg_B = 2'b10; // Light Gray
    end else if (sun_core) begin
      bg_R = 2'b11; bg_G = 2'b11; bg_B = 2'b00; // Yellow
    end else if (sun_aura) begin
      bg_R = 2'b11; bg_G = 2'b10; bg_B = 2'b00; // Orange
    end else if (bird) begin
      bg_R = 2'b00; bg_G = 2'b00; bg_B = 2'b00; // Black
    end else if (cloud) begin
      bg_R = 2'b11; bg_G = 2'b11; bg_B = 2'b11; // White
    end else begin
      bg_R = 2'b01; bg_G = 2'b10; bg_B = 2'b11; // Sky Blue
    end
  end

  // Final multiplexer (Dog on top of background)
  reg [1:0] f_R, f_G, f_B;
  always @(*) begin
    if (nose) begin
      f_R = 2'b00; f_G = 2'b00; f_B = 2'b00; 
    end else if (eye) begin
      f_R = pupil ? 2'b11 : 2'b00;
      f_G = pupil ? 2'b11 : 2'b00;
      f_B = pupil ? 2'b11 : 2'b00;
    end else if (tongue) begin
      f_R = 2'b11; f_G = 2'b01; f_B = 2'b10; 
    end else if (collar) begin
      f_R = 2'b11; f_G = 2'b00; f_B = 2'b00; 
    end else if (tag) begin
      f_R = 2'b11; f_G = 2'b11; f_B = 2'b00; 
    end else if (is_dog_main) begin
      f_R = 2'b11; f_G = 2'b10; f_B = 2'b00; 
    end else if (is_dog_dark) begin
      f_R = 2'b10; f_G = 2'b01; f_B = 2'b00; 
    end else if (is_dog_white) begin
      f_R = 2'b11; f_G = 2'b11; f_B = 2'b11; 
    end else begin
      f_R = bg_R;
      f_G = bg_G;
      f_B = bg_B;
    end
  end

  assign R_vga = video_active ? f_R : 2'b00;
  assign G_vga = video_active ? f_G : 2'b00;
  assign B_vga = video_active ? f_B : 2'b00;

endmodule
