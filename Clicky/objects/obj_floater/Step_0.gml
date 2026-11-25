/// @description drift and fade
x += vx;
y += vy;
vy *= 0.94;
life -= 1;
if (life <= 0) instance_destroy();
