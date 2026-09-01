# machin-brick

Build a robot out of bricks. **The walk falls out of what you built.**

```
./build.sh              build bin/brick
./build.sh test         50 headless assertions, no window
./bin/brick             the workshop; TAB to fight
./bin/brick --spec      what a build added up to
./bin/brick --sim 9     nine battles, no window
```

## The claim

Every game in this family animates by arithmetic rather than by clips, and the
gait rules have never actually known what a body is. They know leg length, hip
width, foot positions, cadence.
[machin-lowpoly](https://github.com/javimosch/machin-lowpoly) half-proved it by
measuring a stranger's rigged glTF and applying the same rules to it.

This is the honest test: **the player hands the program a pile of bricks and it
has to work out whether that has legs, how many, how long they are and what it
weighs — and then the same rules apply.** Two legs and it is the biped gait
from four games ago. Four and it trots. Six and it moves on alternating
tripods. Wheels and it rolls. None of that is a clip, a rig or an animation
set.

And then the part no clip-based game can have: **a leg gets shot off and the
gait is worked out again mid-fight.** A four-legged robot walks away on three
because the solver is now solving a three-legged problem, not because somebody
animated a limp. There is an assertion for exactly that, and it reads
`so it moves differently (trot to crawl)`.

## Nothing is a stat

The design principle that keeps this from being a spreadsheet: **no number in
the game is typed in.** A part says how heavy it is, how much it can take, and
what it does. Everything else is measured off the assembly:

| what | measured from |
|---|---|
| speed | motor torque ÷ total mass |
| turn rate | the same, against a shorter lever |
| gait | how many limbs end in a foot |
| stride, cadence | leg length and speed |
| how high it rides | how long the legs are |
| steadiness | how far apart the feet are, against how high the mass sits |
| recoil | the weapon's impulse at the distance that brick sits from the centre |
| armour | the bricks that are actually there |
| power | batteries against what the guns want |

So the tradeoffs are real without anybody balancing them. A tall stack on two
legs is quick and tips over. A wide four-legged platform is slow and can fire a
rail gun without knocking itself down — **and it knocks itself down if you
build it narrow, because the recoil is applied at the gun's own position and
the feet either hold it or they do not.** Bolting on more armour makes it
slower by exactly the amount the armour weighs.

`--spec` prints what a build became:

```
robot Strider: 21 bricks
  biped, 2 legs, 0 arms
  mass 43.6 kg   torque 68   power 44/12 W
  speed 2.51 m/s   turn 1.73 rad/s   reach 0.72 m
  steadiness 5.35   spread 0.36 m   armour 234
```

## Working out what you built

Cut the graph at every hinge and flood from the core. What you reach is the
**hull**; every island still hanging off a hinge is a **limb**, its root is
that hinge, its end is the brick furthest from it, and what it ends in decides
what it is — a foot makes it a leg, a wheel makes it a wheel, a gun makes it an
arm.

That is the whole derivation, and it is deliberately one idea rather than a
parser: a player who invents a shape nobody anticipated still gets a machine,
because the question being asked of the bricks is only *what does this hang
from and what does it end in*.

## The rules that carried over unchanged

- **The phase advances by distance, not time.** Which matters more here than
  anywhere: a robot's speed comes out of its own torque-to-mass ratio, so it is
  different for every build and changes the moment it loses an arm.
- **The feet lead and the body follows.** Generalising this to N legs needed no
  thought at all: the hull sits at whatever height keeps *every* planted leg
  inside its own length. For two legs that is the humanoid rule; for six it is
  the same line with a longer loop, and the rise and fall of a walking hexapod
  falls out without anybody animating it.
- **Cadence is primitive, stride derived.** A short leg steps more often to
  cover the same ground, exactly as a small animal does.

What is genuinely new is four lines: **which legs are down together.** Biped is
0 and ½; a trot is diagonal pairs, worked out from where the hinges actually
are rather than the order they were built in; a tripod alternates; a crawl
moves one leg at a time. One solver underneath all of them.

### The lead was half what it should be

A planted foot travels `stance × stride` backwards relative to the machine
before it lifts, and a stride is two steps, so for the stance to be symmetric
about the hinge the foot must plant exactly half of that ahead:
`lead = step × stance`.

This file had half of it — which plants the foot a third of the way forward and
lets it finish two thirds of the way back. On a biped that is a slightly odd
walk. On a hexapod, whose legs are spread along the body, it put **ninety-six
feet a frame further from their hinge than the leg was long**. I had derived
this correctly in the previous repo, written it in that README, and then halved
it here. The assertion caught it in a second; watching would have taken an
afternoon and probably found the wrong cause.

## Four bugs, and two of them were one `=`

The first build shipped with four faults, and the interesting thing is how
little they looked like each other:

- **every battle after the first was an instant win**
- **the enemy sometimes spawned lying on the floor**
- **they sometimes circled each other for ever without shooting**
- **and a fight that nobody won never ended**

The first two are the same bug. A `Bot` is a slice of bricks, and **slices
alias**: `f.bt = bt0` copies the struct and shares the bricks, so a fight
fought *with* a robot takes bricks off the robot itself. The second battle was
between two wrecks — and a wreck with no legs is marked down at birth, which is
a machine lying on the floor. One assignment, two symptoms, neither pointing
anywhere near the cause. This family has now been caught by slice aliasing
twice, in two repos, and the assertion that catches the class is the same shape
both times: **fight with a robot and the robot is unchanged.** It has to build
fresh machines to measure, or it is checking bots that the tests above already
took apart — which is how the first version of it passed on the broken code.

The circling was a design bug rather than a slip. Firing was gated on the
**hull's** heading, and a robot that circles its enemy turns to face where it
is *going* — so it was always ninety degrees off its own target and never fired.
The guns now have their own bearing, tracked toward the enemy and limited to
±120° of the hull, which is also what will make flanking mean something later.

And a duel needs a clock. Ninety seconds and it is a draw — a real result,
because it means neither build can finish the other, which is a fact about the
designs worth being told. A machine that has lost every weapon has also lost,
even while it is still walking: it cannot affect the outcome any more.

## The editor could not be rotated

Because the left button places a brick and the right one takes it away, so
neither of them could also mean "look around". Middle-drag orbits now, `Q`/`E`
turn and `R`/`F` pitch, and in the arena the left button orbits too since
nothing else wants it.

Two more things made it feel broken. The build layer is a horizontal plane
somewhere in mid-air with a ghost brick floating on it, and **nothing was drawn
at that height** — so placing anything above the ground was guesswork; there is
a frame at the layer now. And `brick_limb` worked out the hull separately for
every brick it was asked about, which made drawing a robot cubic in its brick
count: a thirty-brick machine cost a quarter of a million grid lookups a frame.
The hull is flooded once per draw.

## Damage is brick removal

A shot takes apart the brick nearest where it landed. Then the connectivity
flood runs — the same one the build editor uses to reject a robot with a brick
floating in mid-air — and anything no longer attached to the core falls off.
**Shoot the shoulder and the whole arm goes, gun included.**

Then the machine is derived again from what is left. A robot that has lost
every leg is not handled by a death rule: `derive` says it has no way to move,
and a thing with no way to move is on the floor.

## Auto-battle

You build it; you do not drive it. Every loss is a fact about the design rather
than about your reflexes, which is the point of a game whose subject is the
design.

The behaviour is derived too. Preferred range comes out of the guns it is
carrying, so a rail-gun build keeps its distance and a cannon build closes —
and a robot that loses its rail gun to a lucky shot starts advancing. The arena
has edges, which is what stops a long-ranged machine backing away for ever and
is the only reason ranged and close builds are a rock-paper-scissors rather
than a dominance.

`--sim 9` runs nine battles with no window and reports the result. It is how
the ten opponents will get balanced, it is how an assertion can say *an unarmed
robot loses*, and it is how a change to the derivation gets checked against a
hundred fights in a second rather than one that somebody sat through.

## What is asserted

Fifty headless assertions, at the two things a screenshot cannot show:
that the derivation found what is really there, and that it still works after
the shape changes.

- a two-legged build walks as a biped, a four-legged one trots, a six-legged
  one moves on alternating tripods
- more bricks weigh more and go slower on the same motors; a wide stance is
  steadier than a tall one — **and none of those three numbers was typed
  anywhere**
- shooting a hinge sheds the whole limb; the machine is then three-legged, it
  moves differently, it is lighter, and it is still a robot — and with no legs
  at all it cannot move
- on two, four and six legs: a planted foot does not slide, no leg over-reaches,
  and the machine does not sink
- a tall chassis falls over firing its own rail gun and a wide one does not
- the same fight twice has the same winner at the same moment, and an unarmed
  robot loses

## The parts

| file | |
|---|---|
| `bk/10_part.src` | eleven kinds of brick, and what each one *does* |
| `bk/20_build.src` | the grid, mirroring, connectivity, the file |
| `bk/30_derive.src` | **the file the idea rests on** — bricks to a machine |
| `bk/40_gait.src` | the family's three rules, for N legs |
| `bk/50_fight.src` | auto-battle, brick removal, and the headless sim |
| `bk/60_draw.src` | a brick is a box with a stud, and the stud earns its four triangles |

## Where it is

The first slice, and it does the thing it was built to prove: place bricks,
watch the thing you designed walk, blow a leg off it, watch the gait re-derive.

Not here yet: the ten prefab opponents and the pick-one-of-three unlock between
them; wheels and arms are derived but barely used; a limb is drawn as a straight
line from hinge to foot rather than bending at a knee; and there is no
save-slot UI beyond `S`.

One deliberate simplification worth naming: **every brick is one cell.** Real
Technic has beams of six lengths and that is a better toy — one cell is a better
POC, because connectivity, damage and the kinematic derivation all become the
same trivial operation on a grid, and the silhouette still reads as bricks
because a brick is drawn with a stud on top.
