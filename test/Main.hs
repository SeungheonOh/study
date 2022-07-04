{-# LANGUAGE ImportQualifiedPost #-}

module Main where

import Test.QuickCheck hiding (NonZero, Positive, Sorted)
import Test.Tasty
import Test.Tasty.ExpectedFailure
import Test.Tasty.Plutarch.Property
import Test.Tasty.QuickCheck hiding (NonZero, Positive, Sorted)

import Plutarch
import Plutarch.Api.V1
import "plutarch" Plutarch.Api.V1.AssocMap qualified as Assoc
import "plutarch" Plutarch.Api.V1.Value qualified as Value
import Plutarch.Evaluate
import Plutarch.Lift
import Plutarch.Prelude
import Plutarch.Show
import Plutarch.Unsafe

import Lib

selfEq :: PEq a => Term s (a :--> PBool)
selfEq = plam $ \x -> x #== x

unsortedMapProp :: Property
unsortedMapProp =
    forAllShow (resize 10 arbitrary) (const "PShow Not Implemented") (fromPFun unsortedMap)
    where
      unsortedMap :: forall s. Term s (PMap Unsorted PInteger PInteger :--> PBool)
      unsortedMap = plam $ \x ->
          selfEq #$ Assoc.passertSorted # ((punsafeCoerce x) :: Term s (PMap Sorted PInteger PInteger))

sortedMapProp :: Property
sortedMapProp =
    forAllShow (resize 10 arbitrary) (const "PShow Not Implemented") (fromPFun sortedMap)
    where
      sortedMap :: Term s (PMap Sorted PInteger PInteger :--> PBool)
      sortedMap = plam $ \x ->
          selfEq #$ Assoc.passertSorted # x

sortedValueProp :: Property
sortedValueProp =
    forAllShow (resize 10 arbitrary) (const "PShow Not Implemented") (fromPFun sortedValue)
    where
      sortedValue :: forall s. Term s (PValue Sorted NonZero :--> PBool)
      sortedValue = plam $ \x ->
          selfEq #$ Value.passertSorted # x
    
positiveSortedValueProp :: Property
positiveSortedValueProp =
    forAllShow (resize 10 arbitrary) (const "PShow Not Implemented") (fromPFun positiveSortedValue)
    where
      positiveSortedValue :: forall s. Term s (PValue Sorted Positive :--> PBool)
      positiveSortedValue = plam $ \x ->
          selfEq #$ Value.passertPositive # (punsafeCoerce x)

unsortedValueProp :: Property
unsortedValueProp =
    forAllShow (resize 10 arbitrary) (const "PShow Not Implmented") (fromPFun unsortedValue)
    where
      unsortedValue :: forall s. Term s (PValue Unsorted NoGuarantees :--> PBool)
      unsortedValue = plam $ \x ->
          selfEq #$ Value.passertSorted # (punsafeCoerce x)
    
main =
    defaultMain $
    testGroup "Tests" $
    [ testGroup "Values" $
      [ testProperty "Generation of Sorted and Normalized Values" $ sortedValueProp
      , testProperty "Generation of Sorted, Normalized, and Positve Values" $ positiveSortedValueProp
      , expectFail $ testProperty "Generation of Unsorted and Un-guaranteed Values" $ unsortedValueProp
      ]
    , testGroup "Map" $
      [ testProperty "Generation of Sorted PMap" $ sortedMapProp
      , expectFail $ testProperty "Generation of Unsorted PMap" $ unsortedMapProp
      ]
    ]

