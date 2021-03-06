open import Relation.Binary
open import Relation.Binary.PropositionalEquality using (_≡_; refl; subst; sym)

open import Level using (_⊔_)
open import Data.Maybe using (Maybe)
open import Data.Product using (Σ)
open Σ
open import Data.List using (List; foldr)
open import Function using (const)

module Tree
  {k r v} (Key : Set k) {_<_ : Rel Key r}
  (is-strict-total-order : IsStrictTotalOrder _≡_ _<_)
  (V : Key -> Set v) where

open import Key Key is-strict-total-order
import AVL Key is-strict-total-order V as Bounded
open Bounded.Insert
open Bounded.Delete

data Tree : Set (k ⊔ v ⊔ r) where
  tree : ∀ {h} -> Bounded.AVL -∞ +∞ h -> Tree

empty : Tree
empty = tree (Bounded.empty -∞<+∞)

singleton : (key : Key) -> V key -> Tree
singleton key value = tree (Bounded.singleton key value (open-bounds key))

lookup : (key : Key) -> Tree -> Maybe (V key)
lookup key (tree avl) = Bounded.lookup key avl

insertWith : (key : Key) -> V key -> (V key -> V key -> V key) -> Tree -> Tree
insertWith key value update (tree avl₁) with Bounded.insertWith key value update (open-bounds key) avl₁
... | +zero avl₂ = tree avl₂
... | +one  avl₂ = tree avl₂

insert : (key : Key) -> V key -> Tree -> Tree
insert key value = insertWith key value const

fromList : List (Σ Key V) -> Tree
fromList = foldr (λ k×v → insert (proj₁ k×v) (proj₂ k×v)) empty

delete : Key -> Tree -> Tree
delete key (tree avl₁) with Bounded.delete key avl₁
... | -zero avl₂ = tree avl₂
... | -one  avl₂ = tree avl₂
