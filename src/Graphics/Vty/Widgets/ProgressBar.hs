-- |This module provides a ''progress bar'' widget which stores a
-- progress value between 0 and 100 inclusive and supports a text
-- label.  Use the 'schedule' function to modify the progress bar's
-- state from a thread.
module Graphics.Vty.Widgets.ProgressBar
    ( ProgressBar
    , newProgressBar
    , setProgress
    , setProgressTextAlignment
    , setProgressText
    , addProgress
    , getProgress
    , onProgressChange
    )
where

import Control.Monad
import qualified Data.Text as T
import Graphics.Vty
import Graphics.Vty.Widgets.Core
import Graphics.Vty.Widgets.Events
import Graphics.Vty.Widgets.Text
import Graphics.Vty.Widgets.Alignment

data ProgressBar = ProgressBar { progressBarAmount :: Int
                               , onChangeHandlers :: Handlers Int
                               , progressBarText :: T.Text
                               , progressBarTextAlignment :: Alignment
                               }

instance Show ProgressBar where
    show p = concat [ "ProgressBar { "
                    , ", " ++ (show $ progressBarAmount p)
                    , ", ... }"
                    ]

-- |Create a new progress bar with the specified completed and
-- uncompleted attributes, respectively.  The foreground of the
-- attributes will be used to show the progress bar's label, if any.
newProgressBar :: Attr -> Attr -> IO (Widget ProgressBar)
newProgressBar completeAttr incompleteAttr = do
  chs <- newHandlers
  t <- plainText T.empty
  let initSt = ProgressBar 0 chs T.empty AlignCenter
  wRef <- newWidget initSt $ \w ->
          w { growHorizontal_ = const $ return True
            , render_ =
                \this size ctx -> do
                  -- Divide the available width according to the
                  -- progress value
                  prog <- progressBarAmount <~~ this
                  txt <- progressBarText <~~ this
                  al <- progressBarTextAlignment <~~ this

                  let complete_width = fromEnum $ (toRational prog / toRational (100.0 :: Double)) *
                                       (toRational $ fromEnum $ region_width size)

                      full_width = fromEnum $ region_width size
                      full_str = T.take full_width $ mkStr txt al

                      mkStr s AlignLeft = T.concat [ s
                                                   , T.pack $ replicate (full_width - T.length txt) ' '
                                                   ]
                      mkStr s AlignRight = T.concat [ T.pack $ replicate (full_width - T.length txt) ' '
                                                    , s
                                                    ]
                      mkStr s AlignCenter = T.concat [ half
                                                     , s
                                                     , half
                                                     , if T.length half * 2 < (full_width + T.length txt)
                                                       then T.singleton ' '
                                                       else T.empty
                                                     ]
                          where
                            half = T.pack $ replicate ((full_width - T.length txt) `div` 2) ' '

                      (complete_str, incomplete_str) = ( T.take complete_width full_str
                                                       , T.drop complete_width full_str
                                                       )

                  setTextWithAttrs t [ (complete_str, completeAttr)
                                     , (incomplete_str, incompleteAttr)
                                     ]
                  render t size ctx
            }

  setProgress wRef 0
  return wRef

-- |Register a handler to be invoked when the progress bar's progress
-- value changes.  The handler will be passed the new progress value.
onProgressChange :: Widget ProgressBar -> (Int -> IO ()) -> IO ()
onProgressChange = addHandler (onChangeHandlers <~~)

-- |Set the progress bar's progress value.  Values outside the allowed
-- range will be ignored.
setProgress :: Widget ProgressBar -> Int -> IO ()
setProgress p amt =
    when (amt >= 0 && amt <= 100) $ do
      updateWidgetState p $ \st -> st { progressBarAmount = amt }
      fireEvent p (onChangeHandlers <~~) amt

-- |Set the progress bar's text label alignment.
setProgressTextAlignment :: Widget ProgressBar -> Alignment -> IO ()
setProgressTextAlignment p al =
    updateWidgetState p $ \st -> st { progressBarTextAlignment = al }

-- |Set the progress bar's text label.
setProgressText :: Widget ProgressBar -> T.Text -> IO ()
setProgressText p s =
    updateWidgetState p $ \st -> st { progressBarText = s }

-- |Get the progress bar's current progress value.
getProgress :: Widget ProgressBar -> IO Int
getProgress = (progressBarAmount <~~)

-- |Add a delta value to the progress bar's current value.
addProgress :: Widget ProgressBar -> Int -> IO ()
addProgress p amt = do
  cur <- getProgress p
  let newAmt = cur + amt
  when (newAmt >= 0 && newAmt <= 100) $
       setProgress p newAmt
