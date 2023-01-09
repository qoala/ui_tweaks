"""
Generates an animation.xml definition with tactical anims alongside the vanilla in-world anims.
"""
import collections
import io
import math
import os
import re
import sys
import types
import xml.etree.ElementTree as ET

DRAW_TEST_COVER_BOX = False
PARAMS = type('RenderParams', (object,), {
    # 0,-88 +/- 115,115/sclY = top corners of the 1x1 cover boxes.
    # y = 88 - 20 to hover slightly over them.
    # y = 0 for the ground layer.
    'x0': 0,
    'y0': 0,
    'sclD': 115,
    # Isometric projection compresses Y axis.
    'projX': 1,
    'projY': 1/1.8,
    # u,v,w coordinates: (u,v) use sclD/sqrt(2) to XY before projection. w uses sclW.
    'sclW': 115})

Dirs = collections.namedtuple('Directions', 'a b c d', defaults=[False, False, False, False])


def addAnim(root, name, *, symbol = 'effect', frameCount = 1, frameRate = 30):
  anim = ET.SubElement(root, 'anim')
  anim.set('name', name)
  anim.set('root', symbol)
  anim.set('numframes', str(frameCount))
  anim.set('framerate', str(frameRate))
  return anim

def addFrame(anim, frameIdx0=0):
  frame = ET.SubElement(anim, 'frame')
  frame.set('idx', str(len(anim) - 1 + frameIdx0))
  frame.set('w', str(0))
  frame.set('h', str(0))
  frame.set('x', str(0))
  frame.set('y', str(0))
  return frame

def buildAnim(root, name, frameFns, *, fnKwargs=None, frameCount=1, frameIdx0=0,
              drawTest=DRAW_TEST_COVER_BOX, **kwargs):
  """
  Define an animation sequence for the given root symbol and animation name using the given
  function(s) for defining each frame.
  """
  anim = addAnim(root, name, frameCount=frameCount, **kwargs)
  if isinstance(frameFns, types.FunctionType):
    frameFns = [frameFns,]
    if fnKwargs is not None:
      fnKwargs = [fnKwargs]
  if fnKwargs is None:
    fnKwargs = [{}] * len(frameFns)

  for i in range(frameCount):
    frame = addFrame(anim, frameIdx0=frameIdx0)
    if drawTest:
      # Tactical cover sprite for checking scale & alignment.
      addElement(frame, 'MF_cover_1x1_tac', tfm=[{'a': 2.5, 'd': 2.5}, {'tx': 0.3, 'ty': -16.349}])
    for fn, fkw in zip(frameFns, fnKwargs):
      fn(frame, i, frameCount, **fkw)

  return anim

def _applyTransformCoord(el, tfm, idx, coord):
  if tfm and (
      isinstance(tfm, dict) and tfm.get(idx) or isinstance(tfm, list) and len(tfm) > idx
      ) and tfm[idx].get(coord) is not None:
    val = tfm[idx][coord]
  elif coord == 'a' or coord == 'd': # scale factors
    val = 1
  else: # shear or translation
    val = 0
  el.set('m%d_%s' % (idx, coord), str(val))

def _applyColorCoord(el, colors, channelIn, channelOut):
  if colors and colors.get(channelIn) and colors[channelIn].get(channelOut) is not None:
    val = colors[channelIn].get(channelOut)
  elif channelIn == channelOut: # red->red, etc.
    val = 1
  else: # red->green, etc.
    val = 0
  el.set('c_%d%d' % (channelIn, channelOut), str(val))

def addElement(frame, imgName, *, imgFrame = 0, depth = 0, tfm = None, colors = None):
  el = ET.SubElement(frame, 'element')
  el.set('name', imgName)
  el.set('layername', '2571176411')
  el.set('parentname', '')
  el.set('frame', str(imgFrame))
  el.set('depth', str(depth))
  # Two sequential affine transformations.
  for idx in [1, 0]:
    for coord in ['a', 'b', 'c', 'd', 'tx', 'ty']:
      _applyTransformCoord(el, tfm, idx, coord)
  # Direct color mappings.
  for i in range(5):
    _applyColorCoord(el, colors, i, i)
  # Cross-channel color mappings.
  for i in range(5):
    for j in range(5):
      if i != j:
        _applyColorCoord(el, colors, i, j)
  return el

def _tfmXY(dx = 0, dy = 0, *, size = 1, projectDeltaOnly = True):
  if projectDeltaOnly:
    # Projection only affects translation coordinates.
    return {1:
        {'a': size, 'd': size,
          'tx': PARAMS.x0 + PARAMS.projX * PARAMS.sclD * dx,
          'ty': PARAMS.y0 + PARAMS.projY * PARAMS.sclD * dy}}
  else:
    # Projection also reshapes the image.
    return [
        {'a': PARAMS.projX, 'd': PARAMS.projY, 'tx': PARAMS.x0, 'ty': PARAMS.y0},
        {'a': size, 'd': size / PARAMS.projY, 'tx': PARAMS.sclD * dx, 'ty': PARAMS.sclD * dy }]

def buildTestFrame(frame, t, tMax, *, size=0.375):
  del t, tMax
  addElement(frame, 'sphere', tfm=_tfmXY( 0,  0, size=size))
  addElement(frame, 'sphere', tfm=_tfmXY( 0,  1, size=size))
  addElement(frame, 'sphere', tfm=_tfmXY( 0, -1, size=size))
  addElement(frame, 'sphere', tfm=_tfmXY( 1,  0, size=size))
  addElement(frame, 'sphere', tfm=_tfmXY(-1,  0, size=size))

def buildSightblockFrame(frame, t, tMax, *, fadeOut=False,
                         dirs=Dirs(True, True, True, True)):
  """Sightblock panels at the edges fo the tile bounds."""
  if fadeOut and t < fadeOut:
    alpha = 1 - (t/fadeOut)**(2/3)
    colors = {3: {3: alpha}}
  elif fadeOut:
    return # Past completion of the fadeOut. Add empty frames to match in-world anim.
  else:
    colors = None

  d = 1/math.sqrt(2)
  tfm1 = {'a': 2.5, 'd': 2.5} # Scale adjustment between prop scale (0.25) and FX scale (0.1)
  def tfm(u=0,v=0,w=0):
    tfm0 = {'tx': PARAMS.projX * PARAMS.sclD * (u + v) / math.sqrt(2),
            'ty': PARAMS.projY * PARAMS.sclD * (u - v) / math.sqrt(2) - PARAMS.sclW * w}
    return [tfm0, tfm1]


  if dirs.d:
    addElement(frame, 'sightblock_E', tfm=tfm(), colors=colors)
  if dirs.a:
    addElement(frame, 'sightblock_N', tfm=tfm(), colors=colors)
  if dirs.b:
    addElement(frame, 'sightblock_W', tfm=tfm(), colors=colors)
  if dirs.c:
    addElement(frame, 'sightblock_S', tfm=tfm(), colors=colors)

def buildOrbitFrame(frame, t, tMax, *,
                    size, fadeOutSize, radius=1/math.sqrt(2), orbCount, period, fadeOut=False):
  """Spheres orbit around a circle that fits in the tile bounds."""
  if fadeOut and t < fadeOut:
    # Volumetric expansion.
    size = size + (fadeOutSize - size) * (t/fadeOut)**(1/3)
    alpha = 1 - (t/fadeOut)**(2/3)
  elif fadeOut:
    return # Past completion of the fadeOut. Add empty frames to match in-world anim.
  else:
    alpha = 1

  tN = t / (period or tMax) # Normalized t.
  def tfmOrbit(orbIdx):
    angle = (orbIdx / orbCount + tN) * 2 * math.pi
    return {
        'tfm': _tfmXY(radius * math.cos(angle), radius * math.sin(angle), size=size),
        # Alpha decreases as it moves towards the background.
        'colors': {3: {3: alpha * (0.7 + 0.3 * math.sin(angle))}}
        }
  for i in range(orbCount):
    addElement(frame, 'sphere', **tfmOrbit(i))

def buildEdgeFrame(frame, t, tMax, *,
                   size, fadeOutSize, radius, orbCount, period, fadeOut=False,
                   lifetime=False, lifecycleOverlap=3, lifecycleStepFn=None, lifecycleStep=1,
                   lifecycleFadeOut=False,
                   dirs=Dirs(True, True, True, True)):
  """Spheres travel along the edge of the tile bounds."""
  if fadeOut and t < fadeOut:
    # Volumetric expansion.
    size = size + (fadeOutSize - size) * (t/fadeOut)**(1/3)
    alphaGlobal = 1 - (t/fadeOut)**(2/3)
  elif fadeOut:
    return # Past completion of the fadeOut. Add empty frames to match in-world anim.
  else:
    alphaGlobal = 1

  tN = t / (period or tMax) # Normalized t.
  def addEdgeOrb(orbIdx, alphaOrb, sizeOrb, testColor=False):
    # Distance within a single side.
    tSide, sideIdx = math.modf((tN + orbIdx / orbCount) * 4)
    sideIdx = sideIdx % 4
    sideFade = False
    if sideIdx == 0:
      if not dirs.a:
        return
      if (tSide < 0.5 and not dirs.d) or (tSide > 0.5 and not dirs.b):
        sideFade = True
      x, y = tSide, 1 - tSide
    elif sideIdx == 1:
      if not dirs.b:
        return
      if (tSide < 0.5 and not dirs.a) or (tSide > 0.5 and not dirs.c):
        sideFade = True
      x, y = 1 - tSide, -tSide
    elif sideIdx == 2:
      if not dirs.c:
        return
      if (tSide < 0.5 and not dirs.b) or (tSide > 0.5 and not dirs.d):
        sideFade = True
      x, y = -tSide, -1 + tSide
    else:
      if not dirs.d:
        return
      if (tSide < 0.5 and not dirs.c) or (tSide > 0.5 and not dirs.a):
        sideFade = True
      x, y = -1 + tSide, tSide

    tfm = _tfmXY(radius * x, radius * y, size=(size if sizeOrb is None else sizeOrb))
    # Alpha fades to 0 at the corners when the next/prev side isn't present.
    if sideFade:
      alphaLocal = 0.5 - 0.5 * math.cos(tSide * 2 * math.pi)
    else:
      alphaLocal = 1
    # Alpha decreases slightly with movement between fg and bg.
    if y < 0:
      alphaLocal *= (1 + 0.4 * y)
    colors = {3: {3: alphaGlobal * alphaLocal * alphaOrb}}
    if testColor:
      colors[2] = {2: 0}
    addElement(frame, 'sphere', tfm=tfm, colors=colors)

  # for i in range(orbCount):
  if lifetime:
    assert lifecycleOverlap >= 2
    tI, idx = math.modf(lifecycleOverlap * t / lifetime)
    idx = int(idx)
    if lifecycleStepFn:
      def iFn(i): return lifecycleStepFn(i) % orbCount
    else:
      def iFn(i): return (lifecycleStep * i) % orbCount
    # Middle lifecycle stages
    orbs = [[iFn(idx - i), 1, None,] for i in range(1, lifecycleOverlap - 1)]
    # First lifecycle stage fades in.
    orbs.insert(0, [iFn(idx), 0.5 - 0.5 * math.cos(tI * math.pi), None,])
    # Last lifecycle stage fades out.
    orbs.append([iFn(idx - lifecycleOverlap + 1), 0.5 + 0.5 * math.cos(tI * math.pi), None,])
    if lifecycleFadeOut:
      orbs = orbs[idx:] # Remove orbs that start after the fade begins.
      if orbs:
        # Volumetric fadeout on the currently fading element.
        orbs[-1][1] = 1 - tI**(2/3)
        orbs[-1][2] = size + (fadeOutSize - size) * tI**(1/3)
  else:
    orbs = [[i, 1, None] for i in range(orbCount)]
  for i, orbAlpha, orbSize in orbs:
    addEdgeOrb(i, orbAlpha, orbSize)
  # if True:
  #   testIdx = 0
  #   for i in range(orbCount):
  #     addEdgeOrb(i, 0.3 if i == testIdx else 0.1, i == testIdx)

def buildPulseFrame(frame, t, tMax, *,
                    sizeMin, sizeMax, alphaMax, period, fadeOut=False):
  """Constant-size sphere in the middle, with outer layers that pulse outwards and fadeOut."""
  if fadeOut and t < fadeOut:
    i0 = t/fadeOut
  elif fadeOut:
    return # Past completion of the fadeOut. Add empty frames to match in-world anim.
  else:
    i0 = 0

  def addPulseOrb(i):
    """Properties as a function of an individual orb's i from 0 to 1."""
    # Volumetric expansion and fadeOut.
    size = sizeMin + (sizeMax - sizeMin) * i**(1/3)
    alpha = alphaMax * (1 - i**(2/3))
    tfm = _tfmXY(0, 0, size=size)
    colors = {3: {3: alpha}}
    addElement(frame, 'sphere', tfm=tfm, colors=colors)

  # Constant sphere
  addPulseOrb(i0)

  # Pulsing sphere(s)
  if fadeOut and t >= period: # Only the first pulse after beginning fadeout.
      return
  elif period:
    i = i0 + (1 - i0) * math.modf(t / period)[0]
    addPulseOrb(i)

def buildDocumentTree():
  root = ET.Element('Anims')
  # To match the vanilla in-world anim, start the pst anim at idx=100.

  # buildAnim(root, 'loop', frameFns=buildTestFrame, drawTest=True)

  # === Opaque cloud and edge tiles
  # Edges hide the central, pulsing sphere and some of the sightblock panels.
  sbFrontKwargs = {'dirs': Dirs(a=True, d=True)}
  sbRearKwargs = {'dirs': Dirs(b=True, c=True)}
  pulseKwargs = {
    'sizeMin': 0.5,
    'sizeMax': 1.0,
    'alphaMax': 0.25,
    'period': 50,
  }
  buildAnim(root, 'loop', symbol='tactical_sightblock', frameCount=100,
            frameFns=[buildSightblockFrame, buildPulseFrame, buildSightblockFrame],
            fnKwargs=[sbFrontKwargs, pulseKwargs, sbRearKwargs])
  sbFrontKwargs['fadeOut'] = 25
  sbRearKwargs['fadeOut'] = 25
  pulseKwargs['fadeOut'] = 75
  buildAnim(root, 'pst', symbol='tactical_sightblock', frameCount=100, frameIdx0=100,
            frameFns=[buildSightblockFrame, buildPulseFrame, buildSightblockFrame],
            fnKwargs=[sbFrontKwargs, pulseKwargs, sbRearKwargs])

  # === Transparent cloud tiles
  pulseKwargs = {
    'sizeMin': 0.8,
    'sizeMax': 1.6,
    'alphaMax': 0.25,
    'period': 50,
  }
  buildAnim(root, 'loop', symbol='tactical_transparent', frameFns=buildPulseFrame,
            frameCount=100, fnKwargs=pulseKwargs)
  pulseKwargs['fadeOut'] = 75
  buildAnim(root, 'pst', symbol='tactical_transparent', frameFns=buildPulseFrame,
            frameCount=100, fnKwargs=pulseKwargs)

  return ET.ElementTree(root)

def openOutputFile():
  assert __file__[-3:] == '.py'
  outfilename = __file__[:-2] + 'xml'
  return open(outfilename, 'w', encoding='utf-8')

def openVanillaFile():
  assert __file__[-3:] == '.py'
  vanillafilename = __file__[:-2] + 'vanilla.xml'
  return open(vanillafilename, 'r', encoding='utf-8')


def main():
  tree = buildDocumentTree()

  ET.indent(tree, space='  ', level=0)
  buf = io.StringIO()
  tree.write(buf, encoding='unicode')
  buf.seek(0)

  # Insert linebreaks within attribute lists before each group of values.
  lineBreakPattern = re.compile(r' (m0_a|m1_a|c_00|c_01)=')

  with openOutputFile() as f, openVanillaFile() as vf:
    f.write('<Anims>\n')
    for line in buf:
      if line.startswith('<'): continue # Skip the outermost layer.
      formattedLine = lineBreakPattern.sub(r'\n' + 10*' ' + r'\1=', line)
      f.write(formattedLine)
    for line in vf:
      if line.startswith('<'): continue # Skip the outermost layer.
      f.write(line)
    f.write('</Anims>\n')


if __name__ == '__main__':
  main()
