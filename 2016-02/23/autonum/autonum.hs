--module Main(main) where

import Data.Array
import Data.Tuple
import Data.Maybe
import Debug.Trace
import Control.Monad
import System.Environment
import Control.Parallel.Strategies

initial :: Array Int Int
initial = listArray (0, 9) [0, 0..]

set :: Int -> Int -> (Array Int Int) -> (Array Int Int)
set num count ary | trace ("set " ++ show num ++ " " ++ show count) False = undefined
set num count ary
  | num < 0   = ary
  | num > 9   = ary
  | count < 0 = ary
  | count > 9 = ary
  | oldcount == count = ary
  | oldval == newval  = newary
  | otherwise =
    set oldcount (oldval - 1)
      (set count (newval + 1)
        newary)

  where
    newary = ary // [(num, count)]
    oldcount = ary ! num
    oldval = newary ! oldcount
    newval = newary ! count

unpack :: (a, a) -> [a]
unpack (a, b) = [a, b]

occurences :: (a, a) -> [(a, Int)]
occurences (a, b) = [(a, 1), (b, 1)]


invertArray :: Array Int Int -> Array Int Int
invertArray ary =
  accumArray (+) 0 (bounds ary) (map swap $ filter (\x -> snd x > 0) $ assocs ary)
  where
    nonzero x = snd x > 0

calcArray :: Array Int Int -> Array Int Int
calcArray ary = accumArray (+) 0 (bounds ary) (concatMap occurences $ filter nonzero $ assocs ary)
  where
    nonzero x = snd x > 0


gen :: Int -> [Array Int Int]
gen n = map (listArray (0, n-1)) $ ( replicateM n [0..n-1])

isAutonum :: Array Int Int -> Bool
isAutonum ary = ary == calcArray ary


display :: Array Int Int -> String
display ary = concat $ withStrategy rdeepseq $ map showEntry $ filter nonzero (assocs ary)
  where
    showEntry = (concat . (map show) . unpack . swap)
    nonzero x = snd x > 0

go :: Int -> String
go n = unlines $ map display $ filter isAutonum (gen n)

converge :: Array Int Int -> Maybe (Array Int Int)
converge ary = convergeBefore 1000 ary


--oob val | trace ("oob " ++ show val) False = undefined


oobArray :: Array Int Int -> Bool
oobArray ary = any oob (assocs ary)
  where
    oob (_, x) = (x > upper) || (x < lower)
    (lower, upper) = bounds ary

convergeBefore :: Int -> Array Int Int -> Maybe (Array Int Int)
convergeBefore 0 _ = Nothing
convergeBefore n ary
  | oobArray nextAry = Just ary
  | ary == nextAry = Just ary
  | otherwise      = convergeBefore (n - 1) nextAry
  where
    nextAry = calcArray ary


goConverge :: Int -> String
goConverge n =
  unlines $ map display $ converges
  where
    converges = catMaybes [converge (initial // [(x, y)]) | x <- [0..n], y <- [0..n]]

--last :: [x] -> x
--last [x] = x
--last (x:xs) = last xs

--main :: IO ()
--main = do
--  [arg] <- getArgs
--  let num = read arg :: Int
--  let result = last $ gen num
--  print result


main :: IO ()
main = do
  [arg] <- getArgs
  let num = read arg :: Int
  let result = goConverge num
  putStr result