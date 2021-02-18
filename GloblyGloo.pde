Glob glob;
Enemy[] enemies;
Wall[] walls;
HashMap input = new HashMap<Integer, Boolean>();

void setup() {
	size(1280, 720);
	smooth(8);

	glob = new Glob(50, 50, 60);
	enemies = new Enemy[] {
		new RoundEnemy(200, 500, 30, 3, .05),
		new MovingEnemy(700, 500, 1000, 400, .002, 30, 3, .05),
	};
	walls = new Wall[] {
		new Wall(width / 2 - 25, 0, 50, height),
	};
}

void draw() {
	background(64);

	boolean anyEnemyColliding = false;
	for (Enemy e : enemies)
		if (e.isColliding(glob)) {
			anyEnemyColliding = true;
			break;
		}
	if (!(mouseIntersecting(glob) || anyEnemyColliding)) {
		glob.update();
	}
	
	for (Enemy e : enemies)
		e.update();

	glob.draw();

	for (Enemy e : enemies)
		e.draw();

	for (Wall w : walls)
		w.draw();

	displayFPS();
}

void displayFPS() {
	fill(#AACCCC);
	textSize(25);
	textAlign(LEFT, TOP);
	text("FPS: " + round(frameRate), 5, 5);
}

void keyPressed() {
	input.put(keyCode, true);
}

void keyReleased() {
	input.put(keyCode, false);
}

boolean keyDown(int k) {
	if (input.containsKey(k))
		return (boolean)input.get(k);
	else
		return false;
}

boolean mouseIntersecting(Glob glob) {
	return dist(glob.x, glob.y, mouseX, mouseY) < glob.r;
}

class Glob {
	float x, y, px, py;
	float r;

	PVector v = new PVector();

	public Glob(float x, float y, float r) {
		this.x = px = x;
		this.y = py = y;
		this.r = r;
	}

	void draw() {
		noStroke();
		fill(#00FF99);
		circle(x, y, r * 2);

		stroke(50);
		
		PVector vn = v.copy();
		vn.normalize();
		line(x, y, x + vn.x * r, y + vn.y * r);
	}

	void update() {
		if (keyDown(87))
			v.y--;
		if (keyDown(83))
			v.y++;
		if (keyDown(65))
			v.x--;
		if (keyDown(68))
			v.x++;

		// if (abs(v.x) > 10 || abs(v.y) > 10) {
		// 	px += v.x / 2;
		// 	py += v.y / 2;

		// 	handleCollision();

		// 	px += v.x / 2;
		// 	py += v.y / 2;

		// 	handleCollision();
		// }
		// else {
			px += v.x;
			py += v.y;

			handleCollision(walls);
		// }

		// float fsX = v.x;
		// float fsY = v.y;
		// println("fives:", fsX, ',', fsY);
		// for (int i = 0; i < max(abs(fsX), abs(fsY)); i++) {
		// 	px += fsX;
		// 	py += fsY;

		// 	handleCollision();

		// 	x = px;
		// 	y = py;
		// }
		// handleCollision();
		keepInBounds();

		v = PVector.lerp(new PVector(), v, keyDown(16) ? .99 : .9); // More Globbly Feel
		// v.mult(.9); // Still Good
		if (abs(v.x) < .3)
			v.x = 0;
		if (abs(v.y) < .3)
			v.y = 0;

		x = px;
		y = py;
	}

	void keepInBounds() {
		px = constrain(px, r, width  - r);
		py = constrain(py, r, height - r);
	}

	void handleCollision(Wall[] walls) {
		// Sliding through wall
		if (keyDown(16))
			return;

		for (Wall w : walls) {
			// If wall is outside glob square, then ignore
			if ((w.x + w.w < px - r || w.y + w.h < py - r) || (w.x > px + r || w.y > py + r))
				continue;

			float nx = constrain(px, w.x, w.x + w.w);
			float ny = constrain(py, w.y, w.y + w.h);
			
			PVector rtn = new PVector(nx - x, ny - y);
			float o = r - abs(rtn.mag());
			
			if (o > 0)
			{
				rtn.normalize();
				px -= rtn.x * o;
				py -= rtn.y * o;

				// v.x *= abs(rtn.x * o * .1);
				// v.y *= abs(rtn.y * o * .1);
			}
		}
	}
}

class Wall {
	float x, y, w, h;

	public Wall(float x, float y, float w, float h) {
		this.x = x;
		this.y = y;
		this.w = w;
		this.h = h;
	}

	void draw() {
		noStroke();
		fill(#FFCCCC);
		rect(x, y, w, h);
	}
}

interface Enemy {
	void draw();
	void update();
	boolean isColliding(Glob glob);
}

class RoundEnemy implements Enemy {
	float x, y, bsy, by, ba, bs; // bsy = base y, by = bob y, ba = bob amount, bs = bob speed
	float r;

	RoundEnemy(float x, float y, float r, float ba, float bs) {
		this.x = x;
		this.bsy = this.y = y;
		this.r = r;
		this.ba = ba;
		this.bs = bs;
	}

	@Override
	void draw() {
		noStroke();
		fill(#FF4444);
		circle(x, y = bsy + sin(by) * ba, r * 2);
	}

	@Override
	void update() {
		by += bs;
	}

	@Override
	boolean isColliding(Glob glob) {
		return dist(x, y, glob.x, glob.y) < r + glob.r;
	}
}

class MovingEnemy implements Enemy {
	float x, y, bsy, by, ba, bs; // bsy = base y, by = bob y, ba = bob amount, bs = bob speed
	float sx, sy, ex, ey;
	float r;

	float prg, sp;
	boolean mf; // marching forward

	MovingEnemy(float sx, float sy, float ex, float ey, float sp, float r, float ba, float bs) {
		this.x = this.sx = sx;
		this.bsy = this.y = this.sy = sy;
		this.ex = ex;
		this.ey = ey;

		this.sp = sp;

		this.r = r;
		this.ba = ba;
		this.bs = bs;
	}

	@Override
	void draw() {
		noStroke();
		fill(#FF1111);
		circle(x, y = bsy + sin(by) * ba, r * 2);
	}

	@Override
	void update() {
		by += bs;

		if (mf) {
			x = lerp(sx, ex, prg);
			y = lerp(sy, ey, prg);
		} else {
			x = lerp(ex, sx, prg);
			y = lerp(ey, sy, prg);
		}
		
		if ((prg += sp) >= 1) {
			prg = 0;
			mf = !mf;
		}
	}

	@Override
	boolean isColliding(Glob glob) {
		return dist(x, y, glob.x, glob.y) < r + glob.r;
	}
}
