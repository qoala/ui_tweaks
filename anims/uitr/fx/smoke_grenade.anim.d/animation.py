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
    'projY': 1/1.8})


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
  el.set('parentname', '2571176411')
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

def buildOrbitFrame(frame, t, tMax, *,
                    size, fadeSize, radius=1/math.sqrt(2), orbCount, period, fade=False):
  """Spheres orbit around a circle that fits in the tile bounds."""
  if fade and t < fade:
    # Volumetric expansion.
    size = size + (fadeSize - size) * (t/fade)**(1/3)
    alpha = 1 - (t/fade)**(2/3)
  elif fade:
      return # Past completion of the fade. Add empty frames to match in-world anim.
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

Dirs = collections.namedtuple('Directions', 'a b c d', defaults=[False, False, False, False])

def buildEdgeFrame(frame, t, tMax, *,
                   size, fadeSize, radius, orbCount, period, fade=False,
                   dirs=Dirs(True, True, True, True)):
  """Spheres travel along the edge of the tile bounds."""
  if fade and t < fade:
    # Volumetric expansion.
    size = size + (fadeSize - size) * (t/fade)**(1/3)
    alphaGlobal = 1 - (t/fade)**(2/3)
  elif fade:
      return # Past completion of the fade. Add empty frames to match in-world anim.
  else:
    alphaGlobal = 1

  tN = t / (period or tMax) # Normalized t.
  def addEdgeOrb(orbIdx):
    # Distance within a single side.
    tSide, sideIdx = math.modf((tN + orbIdx / orbCount) * 4)
    sideIdx = sideIdx % 4
    localFade = False
    if sideIdx == 0:
      if not dirs.a:
        return
      if (tSide < 0.5 and not dirs.d) or (tSide > 0.5 and not dirs.b):
        localFade = True
      x, y = tSide, 1 - tSide
    elif sideIdx == 1:
      if not dirs.b:
        return
      if (tSide < 0.5 and not dirs.a) or (tSide > 0.5 and not dirs.c):
        localFade = True
      x, y = 1 - tSide, -tSide
    elif sideIdx == 2:
      if not dirs.c:
        return
      if (tSide < 0.5 and not dirs.b) or (tSide > 0.5 and not dirs.d):
        localFade = True
      x, y = -tSide, -1 + tSide
    else:
      if not dirs.d:
        return
      if (tSide < 0.5 and not dirs.c) or (tSide > 0.5 and not dirs.a):
        localFade = True
      x, y = -1 + tSide, tSide

    tfm = _tfmXY(radius * x, radius * y, size=size)
    # Alpha fades to 0 at the corners.
    if localFade:
      alphaLocal = 0.5 - 0.5 * math.cos(tSide * 2 * math.pi)
    else:
      alphaLocal = 1
    colors = {3: {3: alphaGlobal * alphaLocal}}
    addElement(frame, 'sphere', tfm=tfm, colors=colors)
  for i in range(orbCount):
    addEdgeOrb(i)

def buildPulseFrame(frame, t, tMax, *,
                    sizeMin, sizeMax, alphaMax, period, fade=False):
  """Constant-size sphere in the middle, with outer layers that pulse outwards and fade."""
  if fade and t < fade:
    i0 = t/fade
  elif fade:
      return # Past completion of the fade. Add empty frames to match in-world anim.
  else:
    i0 = 0

  def addPulseOrb(i):
    """Properties as a function of an individual orb's i from 0 to 1."""
    # Volumetric expansion and fade.
    size = sizeMin + (sizeMax - sizeMin) * i**(1/3)
    alpha = alphaMax * (1 - i**(2/3))
    tfm = _tfmXY(0, 0, size=size)
    colors = {3: {3: alpha}}
    addElement(frame, 'sphere', tfm=tfm, colors=colors)

  # Constant sphere
  addPulseOrb(i0)

  # Pulsing sphere(s)
  i = i0 + (1 - i0) * math.modf(t / period)[0]
  addPulseOrb(i)

def buildDocumentTree():
  root = ET.Element('Anims')
  # To match the vanilla in-world anim, start the pst anim at idx=100.

  # buildAnim(root, 'loop', frameFns=buildTestFrame, drawTest=True)

  # === Smoke cloud tiles
  orbitKwargs = {
    'size': 0.6,
    'fadeSize': 1.2, # 2x expansion.
    'orbCount': 3,
    'period': 300
  }
  buildAnim(root, 'loop', symbol='tactical', frameFns=buildOrbitFrame,
            frameCount=100, fnKwargs=orbitKwargs)
  orbitKwargs['fade'] = 75
  buildAnim(root, 'pst', symbol='tactical', frameFns=buildOrbitFrame,
            frameCount=100, frameIdx0=100, fnKwargs=orbitKwargs)

  # === Smoke edge tiles
  edgeDirs = [
    ['_E_',  '', Dirs(d=True)],
    ['_SE_', '', Dirs(d=True, c=True)],
    ['_S_',  '', Dirs(c=True)],
    ['_SW_', '', Dirs(c=True, b=True)],
    ['_W_',  '', Dirs(b=True)],
    ['_NW_', '', Dirs(b=True, a=True)],
    ['_N_',  '', Dirs(a=True)],
    ['_NE_', '', Dirs(a=True, d=True)],
    ['_E_W_',  '_1_1', Dirs(b=True, d=True)],
    ['_N_S_',  '_1_1', Dirs(a=True, c=True)],
    ['_E_',  '_3', Dirs(a=True, d=True, c=True)],
    ['_S_',  '_3', Dirs(d=True, c=True, b=True)],
    ['_W_',  '_3', Dirs(c=True, b=True, a=True)],
    ['_N_',  '_3', Dirs(b=True, a=True, d=True)],
    ['', '_full', Dirs(a=True, b=True, c=True, d=True)]
  ]
  for animSuffix, symSuffix, dirs in edgeDirs:
    edgeKwargs = {
      'size': 0.3,
      'fadeSize': 0.9, # 3x expansion.
      'radius': 1.5,
      'orbCount': 6,
      'period': 300,
      'dirs': dirs
    }
    buildAnim(root, 'loop' + animSuffix, symbol='tactical_edge' + symSuffix,
              frameFns=buildEdgeFrame,
              frameCount=100, fnKwargs=edgeKwargs)
    edgeKwargs['fade'] = 75
    buildAnim(root, 'pst' + animSuffix, symbol='tactical_edge' + symSuffix, frameFns=buildEdgeFrame,
              frameCount=100, frameIdx0=100, fnKwargs=edgeKwargs)

  # === Transparent cloud tiles
  pulseKwargs = {
    'sizeMin': 0.8,
    'sizeMax': 1.6,
    'alphaMax': 0.25,
    'period': 50,
  }
  buildAnim(root, 'loop', symbol='tactical_transparent', frameFns=buildPulseFrame,
            frameCount=100, fnKwargs=pulseKwargs)
  pulseKwargs['fade'] = 75
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
