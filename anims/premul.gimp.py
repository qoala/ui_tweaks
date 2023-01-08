#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# GIMP plugin to apply and reverse the pre-multiplied Alpha transform used by KWAD packing.
#
# Based on https://github.com/jfmdev/PythonFuSamples
#

import math
from gimpfu import *
from array import array

def _createTmpLayer(img, layer):
  pos = 0;
  for i in range(len(img.layers)):
    if (img.layers[i] == layer):
      pos = i
  newLayer = gimp.Layer(img, layer.name + " _temp",
                        layer.width, layer.height, layer.type, layer.opacity, layer.mode)
  img.add_layer(newLayer, pos)
  pdb.gimp_edit_clear(newLayer)
  newLayer.flush()
  return newLayer

def _finishTmpLayer(img, origLayer, tmpLayer):
  tmpLayer.flush()
  tmpLayer.merge_shadow(True)
  tmpLayer.update(0, 0, tmpLayer.width, tmpLayer.height)

  layerName = origLayer.name
  img.remove_layer(origLayer)
  tmpLayer.name = layerName
  return tmpLayer

def _iterTiles(inLayer, outLayer):
  tn = int(inLayer.width / gimp.tile_width())
  if (inLayer.width % gimp.tile_width() > 0):
    tn += 1
  tm = int(inLayer.height / gimp.tile_height())
  if (inLayer.height % gimp.tile_height() > 0):
    tm += 1

  for i in range(tn):
    for j in range(tm):
      gimp.progress_update(float(i*tm + j) / float(tn*tm))

      yield inLayer.get_tile(False, j, i), outLayer.get_tile(False, j, i)

def _iterPixels(inTile):
    for x in range(inTile.ewidth):
      for y in range(inTile.eheight):
        yield x, y, inTile[x,y]

def premul_alpha(img, layer):
  gimp.progress_init("Pre-Multiplying Alpha " + layer.name + "...")
  pdb.gimp_image_undo_group_start(img)

  try:
    newLayer = _createTmpLayer(img, layer)

    for inTile, outTile in _iterTiles(layer, newLayer):
      for x,y,pxl in _iterPixels(inTile):
        a = ord(pxl[3])
        r = int(round(ord(pxl[0]) * a / float(0xFF)))
        g = int(round(ord(pxl[1]) * a / float(0xFF)))
        b = int(round(ord(pxl[2]) * a / float(0xFF)))
        outTile[x,y] = chr(r) + chr(g) + chr(b) + pxl[3]

    _finishTmpLayer(img, layer, newLayer)
  except Exception as err:
    gimp.message("Unexpected error: " + str(err))

  pdb.gimp_image_undo_group_end(img)
  pdb.gimp_progress_end()

ZERO_PXL = "\x00\x00\x00\x00"

def depremul_alpha(img, layer):
  gimp.progress_init("Pre-Multiplying Alpha " + layer.name + "...")
  pdb.gimp_image_undo_group_start(img)

  try:
    newLayer = _createTmpLayer(img, layer)

    divZeroCount = 0
    overflowCount = 0
    for inTile, outTile in _iterTiles(layer, newLayer):
      for x,y,pxl in _iterPixels(inTile):
        a = ord(pxl[3])
        r0 = ord(pxl[0])
        g0 = ord(pxl[1])
        b0 = ord(pxl[2])
        if a == 0:
          if pxl != ZERO_PXL:
            divZeroCount += 1
            if divZeroCount <= 1:
              gimp.message("Warning: Non-empty pixel with alpha=0: %02x,%02x,%02x,%02x"
                           % (r0, g0, b0, a))
          outTile[x,y] = pxl
          continue
        r = int(round(r0 * 0xFF / float(a)))
        g = int(round(g0 * 0xFF / float(a)))
        b = int(round(b0 * 0xFF / float(a)))
        if r > 0xFF or g > 0xFF or b > 0xFF:
          overflowCount += 1
          if overflowCount <= 1:
            gimp.message("Warning: Overflow: %02x,%02x,%02x,%02x -> %02x,%02x,%02x."
                         % (r0, g0, b0, a, r, g, b))
          r = min(r, 0xFF)
          g = min(g, 0xFF)
          b = min(b, 0xFF)
        outTile[x,y] = chr(r) + chr(g) + chr(b) + pxl[3]

    if divZeroCount > 0:
      gimp.message("Warning: %d DIV0 pixels" % divZeroCount)
    if overflowCount > 0:
      gimp.message("Warning: %d overflow pixels" % overflowCount)
    _finishTmpLayer(img, layer, newLayer)
  except Exception as err:
    gimp.message("Unexpected error: " + str(err))

  pdb.gimp_image_undo_group_end(img)
  pdb.gimp_progress_end()

register(
        "python_fu_qed_kwad_premul",
        "Pre-Multiply Alpha for KWADs",
        "Pre-Multiply Alpha for KWADs",
        "Qoalabear",
        "",
        "",
        "<Image>/Filters/QED/Pre-Multiply Alpha",
        "RGBA",
        [],
        [],
        premul_alpha)
register(
        "python_fu_qed_kwad_depremul",
        "Reverse Pre-Multiply Alpha for KWADs",
        "Reverse Pre-Multiply Alpha for KWADs",
        "Qoalabear",
        "",
        "",
        "<Image>/Filters/QED/Reverse Pre-Multiply Alpha",
        "RGBA",
        [],
        [],
        depremul_alpha)

main()
