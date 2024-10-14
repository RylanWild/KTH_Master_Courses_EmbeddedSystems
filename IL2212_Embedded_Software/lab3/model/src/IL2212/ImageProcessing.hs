-----------------------------------------------------------------------------
  -- |
-- Module      :  IL2212.ImageProcessing
-- Copyright   :  (c) George Ungureanu, 2018
--                (c) Rodolfo Jordao, 2020
-- License     :  BSD-style (see the file LICENSE)
-- 
-- Maintainer  :  jordao@kth.se
-- Stability   :  stable
-- Portability :  portable
--
-- Contains the image processing functions as well as the DUT process
-- network instantiation.
-----------------------------------------------------------------------------
module IL2212.ImageProcessing (
  -- * Type aliases
  Image, Control,
  -- * Functions on images
  grayscale, brightness, correction,
  resize, sobel, toAsciiArt,
  -- * SDF process network
  mooreSDF,
  imageProcessingSDF
                                ) where

import ForSyDe.Shallow
import IL2212.Utilities

-- | Type alias for image as matrix
type Image a = Vector (Vector a)

-- | Data type capturing two states, used for control signals.
data Control = Enable | Disable deriving (Show, Eq)


-- | List with grayscale levels encoded as ASCII characters
asciiLevels :: [Char]
asciiLevels = [' ','.',':','-','=','+','/','t','z','U','w','*','0','#','%','@']

------------------------------------------------------------
  --              Image processing functions                --
------------------------------------------------------------

-- | Converts an image of pixels into its grayscale equivalent using
-- the formula <<resources/grayscale.png>>
grayscale :: Image Int -> Image Double
grayscale = mapMatrix (convert . fromVector) . mapV (groupV 3)
  where
    convert [r,g,b] = fromIntegral r * 0.3125
                    + fromIntegral g * 0.5625
                    + fromIntegral b * 0.125
    convert _ = error "X length is not a multiple of 3"

-- | Resizes an image using a technique based on interpolation, using
-- the transformation below:
--
-- <<resources/resize.png>>
resize :: Image Double -> Image Double
resize = mapMatrix (/ 4) . sumRows . sumCols
  where
    sumCols = mapV (mapV (reduceV (+)) . groupV 2)
    sumRows = mapV (reduceV (zipWithV (+))) . groupV 2

-- | Reduces an image to two numbers :
--
-- * the minimum brightness level
--
-- * the maximum brightness level
brightness :: Image Double -- ^ input image
           -> [Double]     -- ^ list with 2 numbers: the minimum and
-- maximum brigtness levels
brightness img = [minimumBrightness, maximumBrightness]
  where
    maximumBrightness = reduceMatrix max img
    minimumBrightness = reduceMatrix min img

-- | Corrects the brightness level in a picture, based on the
-- previously-identified minimum and maximum values, using four
-- threshold levels.
correction :: Double       -- ^ minimum brightness level
           -> Double       -- ^ maximum brightness level
           -> Image Double -- ^ input image
           -> Image Double -- ^ output image
correction hmin hmax = mapMatrix rescale
  where
    rescale h
      | hmax - hmin > 127 =  h
      | hmax - hmin > 63  = (h - hmin) * 2
      | hmax - hmin > 31  = (h - hmin) * 4
      | hmax - hmin > 15  = (h - hmin) * 8
      | otherwise         = (h - hmin) * 16

-- | Performs edge detection using the
-- <https://en.wikipedia.org/wiki/Sobel_operator Sobel operator>.
--
-- Edges are areas with strong intensity contrasts in an image. This
-- algorithm calculates abrupt changes and their magnitude, based on
-- the gradient of intensity at each point in the image. It is
-- specified using a /stencil parallel pattern/, which:
--
-- * performs <https://en.wikipedia.org/wiki/Convolution convolution>
-- of the original image with two kernel matrices /Kx/ and /Ky/, one
-- for detecting changes in the /x/-direction and one for the
-- /y/-direction. This results in two gradient matrices /Gx/ and /Gy/.
-- 
-- * combines the two approximations to obtain the gradient magnitude
-- /G/.
-- 
-- * scales the magnitude matrix to be correctly represented in
-- grayscale format.
--
-- <<resources/sobel.png>>
sobel :: Image Double -> Image Double
sobel img = dropMargins $ zipWithMatrix (\x y -> sqrt (x ** 2 + y ** 2) / 4) gx gy
  where
    dropMargins = mapV (tailV . initV) . tailV . initV
    gx = reduceV (zipWithMatrix (+)) (vector [gx11, gx13, gx21, gx23, gx31, gx33])
    gy = reduceV (zipWithMatrix (+)) (vector [gy11, gy12, gy13, gy31, gy32, gy33])
    ------------------------------------------------------
    gx11 = mapMatrix (* (-1)) (rotateMatrix   1    1  img)
--  gx12 = mapMatrix (*   0 ) (rotateMatrix   0    1  img)
    gx13 = mapMatrix (*   1 ) (rotateMatrix (-1)   1  img)
    gx21 = mapMatrix (* (-2)) (rotateMatrix   1    0  img)
--  gx22 = mapMatrix (*   0 ) img
    gx23 = mapMatrix (*   2 ) (rotateMatrix (-1)   0  img)
    gx31 = mapMatrix (* (-1)) (rotateMatrix   1  (-1) img)
--  gx32 = mapMatrix (*   0 ) (rotateMatrix   0  (-1) img)
    gx33 = mapMatrix (*   1 ) (rotateMatrix (-1) (-1) img)
    ------------------------------------------------------
    gy11 = mapMatrix (* (-1)) (rotateMatrix   1    1  img)
    gy12 = mapMatrix (* (-2)) (rotateMatrix   0    1  img)
    gy13 = mapMatrix (* (-1)) (rotateMatrix (-1)   1  img)
--  gy21 = mapMatrix (*   0 ) (rotateMatrix   1    0  img)
--  gy22 = mapMatrix (*   0 ) img
--  gy23 = mapMatrix (*   0 ) (rotateMatrix   1    0  img)
    gy31 = mapMatrix (*   1 ) (rotateMatrix   1  (-1) img)
    gy32 = mapMatrix (*   2 ) (rotateMatrix   0  (-1) img)
    gy33 = mapMatrix (*   1 ) (rotateMatrix (-1) (-1) img)

-- | Converts a 256-value grayscale image to a 16-value ASCII art
-- image.
toAsciiArt :: Image Double -> Image Char
toAsciiArt = mapMatrix num2char
  where
    num2char n = asciiLevels !! level n
    level n = truncate $ nLevels * (n / 255)
    nLevels = fromIntegral $ length asciiLevels - 1

-------------------------------------------------------------
  --                SDF process network                      --
-------------------------------------------------------------

-- | The graySDF actor, which transforms a every RGB image from a stream
-- into a grayscale one. In this case it is assumed that the X dimension holds the additional information.
graySDF :: Int -- ^ dimension X for input images
        -> Int -- ^ dimension Y for input images
        -> Signal Int -- ^ stream of pixels from the RGB image
        -> Signal Double -- ^ stream of resulting grayscale pixels
graySDF dimX dimY = actor11SDF (3 * dimX * dimY) (dimX * dimY) (wrapImageF (3 * dimX) dimY grayscale)

-- | The sobel SDF actor, which applies the Sobel operator in the image stream.
sobelSDF :: Int -- ^ dimension X for input images
         -> Int -- ^ dimension Y for input images
         -> Signal Double -- ^ stream of pixels for the image to be sobel'd.
         -> Signal Double -- ^ stream of resulting gradient magnitude.
sobelSDF dimX dimY = actor11SDF (dimX * dimY) (reducedDimX * reducedDimY) (wrapImageF dimX dimY sobel)
  where
    reducedDimX = dimX - 2
    reducedDimY = dimY - 2

-- | The ASCII actor, which outputs the ASCII 'art' of the image stream.
asciiSDF :: Int -- ^ dimension X for input images
         -> Int -- ^ dimension Y for input images
         -> Signal Double -- ^ stream of pixels to be printed
         -> Signal Char -- ^ stream of resulting ASCII pixels
asciiSDF dimX dimY = actor11SDF (dimX * dimY) (dimX * dimY) (wrapImageF dimX dimY toAsciiArt)

-- | This function serves as a wrapper for the correctionSDF since the actor
-- acquires input from others to decide if correction should be applied or not
correctionFunc :: Int -> Int -> [Control] -> [Double] -> [Double] -> [Double]
correctionFunc dimX dimY [Disable] _           = wrapImageF dimX dimY id
correctionFunc dimX dimY [Enable ] [hmin,hmax] = wrapImageF dimX dimY (correction hmin hmax)
correctionFunc dimX dimY _         _           = error "correctFunc: invalid process function"

-- | The correction actor, which outputs a brightness correction according 
-- to its function.
correctionSDF :: Int -- ^ dimension X for input images
              -> Int -- ^ dimension Y for input images
              -> Signal Control -- ^ control signal stream
              -> Signal Double -- ^ stream of maxima and minima
              -> Signal Double -- ^ stream of input image pixels
              -> Signal Double -- ^ stream of output image pixels
correctionSDF dimX dimY = actor31SDF (1, 2, dimX * dimY) (dimX * dimY) (correctionFunc dimX dimY)

-- | the resize actor, which performs a interpolation for eavery image in the stream.
-- In this case from the defining function the dimensions get halved.
resizeSDF :: Int -- ^ dimension X for input images
          -> Int -- ^ dimension Y for input images
          -> Signal Double -- ^ stream of pixels to te interpolated
          -> Signal Double -- ^ stream of resulting interpolated pixels
resizeSDF dimX dimY = actor11SDF (dimX * dimY) (resizedDimX * resizedDimY) (wrapImageF dimX dimY resize)
  where
    resizedDimX = dimX `div` 2
    resizedDimY = dimY `div` 2

-- | the brightness actor, which output the maximum and minimum bright pixels
-- for every image in the stream.
brightnessSDF :: Int -- ^ dimension X for input images
              -> Int -- ^ dimension Y for input images
              -> Signal Double -- ^ stream of pixels to be analyzed
              -> Signal Double -- ^ stream of maxima and minima
brightnessSDF dimX dimY = actor11SDF (dimX * dimY) 2 (brightness . toImage dimX dimY)

-- | Process constructor which builds a process network pattern
-- similar to that of a Moore state machine, but using SDF processes
-- for manipulating the next state, output decoder and initial
-- state. The functions passed to the SDF processes for next state and
-- output decoding are wrapped in triples along with the production
-- and consumption rates.
--
-- /*/ : input for next state process
-- @ ((consumption_from_state_signal, consumption_from_input_signal), production, next_state_function) @
--
-- /**/ : input for output decoder process
-- @ (consumption_from_state_signal, production, output_decoder_function) @
mooreSDF :: ((Int,Int), Int, [st]->[a]->[st]) -- ^ /*/
         -> ( Int,      Int, [st]->[b])       -- ^ /**/
         -> [st]      -- ^ list with initial tokens present on the self-loop
         -> Signal a  -- ^ input signal
         -> Signal b  -- ^ output signal
mooreSDF ((consState,consInput),prodState,nextStateFunc) (consOut,prodOut,outputFunc) initTokens inSig = outSig
  where
    nextStateSig = actor21SDF (consState,consInput) prodState nextStateFunc stateSig inSig
    stateSig = delaySDF initTokens nextStateSig
    outSig = actor11SDF consOut prodOut outputFunc stateSig

-- | the control actor, which keeps an average of levels for some images in the stream and
-- outputs the control signal for the latest image being processed. It uses the mooreSDF
-- patter to achieve this functionality.
controlSDF :: Signal Double
           -> Signal Control
controlSDF = mooreSDF ((3, 2), 3, maxMinToLevel) (3, 1, (averageOfLevels 3)) [255, 255, 255]
  where
    maxMinToLevel :: [Double] -> [Double] -> [Double] -- revolving buffer with lists
    maxMinToLevel state [hmin, hmax] = (hmax-hmin) : init state
    maxMinToLevel _     _            = error "nextStateFunc: invalid process function"

    averageOfLevels :: Int -> [Double] -> [Control]
    averageOfLevels n levels = if (sum levels / fromIntegral n) < 128
                                  then [Enable]
                             else [Disable]

-- | SDF process network chaining a series of image processing
-- algorithms upon a stream of pixel values originating from a
-- <https://en.wikipedia.org/wiki/Netpbm_format PPM image>.
imageProcessingSDF :: Int         -- ^ dimension X of the input image
                   -> Int         -- ^ dimension Y of the input image
                   -> Signal Int  -- ^ Input stream of pixel values
                   -> Signal Char -- ^ Output stream of ASCII characters
imageProcessingSDF dimX dimY inSig = processedImageSig
  where
    processedImageSig = asciiSDF gradientDimX gradientDimY sobelSig
    sobelSig = sobelSDF halfDimX halfDimY correctedSig
    correctedSig = correctionSDF halfDimX halfDimY controlSig brightnessSig resizedSig
    controlSig = controlSDF brightnessSig
    brightnessSig = brightnessSDF halfDimX halfDimY resizedSig
    resizedSig = resizeSDF dimX dimY graySig
    graySig = graySDF dimX dimY inSig

    halfDimX = dimX `div` 2
    halfDimY = dimY `div` 2
    gradientDimX = (halfDimX) - 2
    gradientDimY = (halfDimY) - 2
{-
  -
 -        correctSDF    = actor31SDF (1, 2, x2 * y2) (x2 * y2) correctFunc
 -        resizedSig    = actor11SDF (x1 * y1) (x2 * y2) (wrapImageF x1 y1 resize) sig
 -        brightnessSig = actor11SDF (x2 * y2) 2 (brightness . toImage x2 y2) resizedSig
 -    graySDF  = actor11SDF (x0 * y1) (x1 * y1) (wrapImageF x0 y1 grayscale )
 -    sobelSDF = actor11SDF (x2 * y2) (x3 * y3) (wrapImageF x2 y2 sobel     )
 -    asciiSDF = actor11SDF (x3 * y3) (x3 * y3) (wrapImageF x3 y3 toAsciiArt)
 -    resizeAndCorrectSDF sig = correctSDF controlSig brightnessSig resizedSig
 -      where
   -        correctSDF    = actor31SDF (1, 2, x2 * y2) (x2 * y2) correctFunc
 -        resizedSig    = actor11SDF (x1 * y1) (x2 * y2) (wrapImageF x1 y1 resize) sig
 -        brightnessSig = actor11SDF (x2 * y2) 2 (brightness . toImage x2 y2) resizedSig
 -        controlSig    = mooreSDF
 -                          ((3,2), 3, nextStateFunc)
 -                          ( 3   , 1, outDecodeFunc 3)
 -                          [255,255,255]
 -                          brightnessSig
 -    ------------------------------------------------------------
   -      -- Process functions
 -    ------------------------------------------------------------
   -      correctFunc :: [Control] -> [Double] -> [Double] -> [Double]
 -    correctFunc [Disable] _           = wrapImageF x2 y2 id
 -    correctFunc [Enable ] [hmin,hmax] = wrapImageF x2 y2 (correction hmin hmax)
 -    correctFunc _         _           = error "correctFunc: invalid process function"
 -    ------------------------------------------------------------
 -      nextStateFunc :: [Double] -> [Double] -> [Double] -- revolving buffer with lists
 -    nextStateFunc state [hmin, hmax] = (hmax-hmin) : init state
 -    nextStateFunc _     _            = error "nextStateFunc: invalid process function"
 -    ------------------------------------------------------------
   -      outDecodeFunc :: Int -> [Double] -> [Control]
 -    outDecodeFunc n levels = if (sum levels / fromIntegral n) < 128
 -                                then [Enable]
 -                             else [Disable]
 -    ------------------------------------------------------------
 -      -- Production / consumption rates
   -    ------------------------------------------------------------
     -      --
 -
   -
     -}
