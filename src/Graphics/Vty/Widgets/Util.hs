module Graphics.Vty.Widgets.Util
    ( on
    , fgColor
    , bgColor
    , style
    , mergeAttr
    , mergeAttrs
    , withWidth
    , withHeight
    , plusWidth
    , plusHeight
    )
where

import Data.Word
import Graphics.Vty

-- |Infix attribute constructor.  Use: foregroundColor `on`
-- backgroundColor.
on :: Color -> Color -> Attr
on a b = def_attr `with_back_color` b `with_fore_color` a

-- |Foreground-only attribute constructor.  Background color and style
-- are defaulted.
fgColor :: Color -> Attr
fgColor = (def_attr `with_fore_color`)

-- |Background-only attribute constructor.  Foreground color and style
-- are defaulted.
bgColor :: Color -> Attr
bgColor = (def_attr `with_back_color`)

-- |Style-only attribute constructor.  Colors are defaulted.
style :: Style -> Attr
style = (def_attr `with_style`)

-- Left-most attribute's fields take precedence.
-- |Merge two attributes.  Leftmost attribute takes precedence where
-- it specifies any of the foreground color, background color, or
-- style.
mergeAttr :: Attr -> Attr -> Attr
mergeAttr a b =
    let b1 = case attr_style a of
               SetTo v -> b `with_style` v
               _ -> b
        b2 = case attr_fore_color a of
               SetTo v -> b1 `with_fore_color` v
               _ -> b1
        b3 = case attr_back_color a of
               SetTo v -> b2 `with_back_color` v
               _ -> b2
    in b3

-- |List fold version of 'mergeAttr'.
mergeAttrs :: [Attr] -> Attr
mergeAttrs attrs = foldr mergeAttr def_attr attrs

-- |Modify the width component of a 'DisplayRegion'.
withWidth :: DisplayRegion -> Word -> DisplayRegion
withWidth (DisplayRegion _ h) w = DisplayRegion w h

-- |Modify the height component of a 'DisplayRegion'.
withHeight :: DisplayRegion -> Word -> DisplayRegion
withHeight (DisplayRegion w _) h = DisplayRegion w h

-- |Modify the width component of a 'DisplayRegion'.
plusWidth :: DisplayRegion -> Word -> DisplayRegion
plusWidth (DisplayRegion w' h) w =
    if (fromEnum w' + fromEnum w < 0)
    then error $ "plusWidth: would overflow on " ++ (show w') ++ " + " ++ (show w)
    else DisplayRegion (w + w') h

-- |Modify the height component of a 'DisplayRegion'.
plusHeight :: DisplayRegion -> Word -> DisplayRegion
plusHeight (DisplayRegion w h') h =
    if (fromEnum h' + fromEnum h < 0)
    then error $ "plusHeight: would overflow on " ++ (show h') ++ " + " ++ (show h)
    else DisplayRegion w (h + h')
