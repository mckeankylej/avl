open import Relation.Binary using
  (Rel; IsStrictTotalOrder; Tri)
open Tri
open import Relation.Binary.PropositionalEquality using
  (_≡_; refl; subst; sym)

open import Level using (_⊔_)
open import Data.Nat using (ℕ; pred; _+_)
open ℕ
open import Data.Maybe using (Maybe)
open Maybe
open import Data.Product using (_×_; _,_)

module AVL
  {k r v} (Key : Set k) {_<_ : Rel Key r}
  (is-strict-total-order : IsStrictTotalOrder _≡_ _<_)
  (V : Key -> Set v) where

open import Key Key is-strict-total-order
open IsStrictTotalOrder is-strict-total-order

infix 4 ∣_-_∣↦_
data ∣_-_∣↦_ : ℕ -> ℕ -> ℕ -> Set where
  ↦l : ∀ {h} → ∣ suc h - h ∣↦ suc h
  ↦b : ∀ {h} → ∣ h   -   h ∣↦ h
  ↦r : ∀ {h} → ∣ h - suc h ∣↦ suc h

∣h-l∣↦h : ∀ {l r h} -> ∣ l - r ∣↦ h -> ∣ h - l ∣↦ h
∣h-l∣↦h ↦l = ↦b
∣h-l∣↦h ↦b = ↦b
∣h-l∣↦h ↦r = ↦l

∣r-h∣↦h : ∀ {l r h} -> ∣ l - r ∣↦ h -> ∣ r - h ∣↦ h
∣r-h∣↦h ↦l = ↦r
∣r-h∣↦h ↦b = ↦b
∣r-h∣↦h ↦r = ↦b

∣[h-1]-h∣↦h : ∀ {h} -> ∣ pred h - h ∣↦ h
∣[h-1]-h∣↦h {zero}  = ↦b
∣[h-1]-h∣↦h {suc h} = ↦r

data AVL (l-bound r-bound : Bound) : (height : ℕ) -> Set (k ⊔ v ⊔ r) where
  Leaf : l-bound <ᵇ r-bound -> AVL l-bound r-bound 0
  Node :
    ∀ {h-left h-right h}
      (key     : Key)
      (value   : V key)
      (left    : AVL l-bound [ key ] h-left)
      (right   : AVL [ key ] r-bound h-right)
      (balance : ∣ h-left - h-right ∣↦ h)
    → AVL l-bound r-bound (suc h)

empty : ∀ {l-bound r-bound} -> l-bound <ᵇ r-bound -> AVL l-bound r-bound 0
empty = Leaf

singleton
  : ∀ {l-bound r-bound} (key : Key)
   -> V key
   -> l-bound < key < r-bound
   -> AVL l-bound r-bound 1
singleton key value bst = Node key value (Leaf (lower bst)) (Leaf (upper bst)) ↦b

lookup : ∀ {h} {l-bound r-bound} -> (key : Key) -> AVL l-bound r-bound h -> Maybe (V key)
lookup key₁ (Leaf _) = nothing
lookup key₁ (Node key₂ value left right balance) with compare key₁ key₂
... | tri< _ _ _ = lookup key₁ left
... | tri≈ _ key₁≡key₂ _ = just (subst V (sym key₁≡key₂) value)
... | tri> _ _ _ = lookup key₁ right

data Insert (l-bound r-bound : Bound) (height : ℕ) : Set (k ⊔ v ⊔ r) where
  +0 : AVL l-bound r-bound height       -> Insert l-bound r-bound height
  +1 : AVL l-bound r-bound (suc height) -> Insert l-bound r-bound height

postulate
  undefined : ∀ {a} {A : Set a} -> A

balance-leftⁱ
  : ∀ {h-left h-right h}
      {l-bound r-bound}
      (key : Key)
    -> V key
    -> Insert l-bound [ key ] h-left
    -> AVL [ key ] r-bound h-right
    -> ∣ h-left - h-right ∣↦ h
    -> Insert l-bound r-bound (suc h)
balance-leftⁱ key₁ value₁ (+0 left₁) right₁ balance = +0 (Node key₁ value₁ left₁ right₁ balance)
balance-leftⁱ key₁ value₁ (+1 left) right ↦r = +0 (Node key₁ value₁ left right ↦b)
balance-leftⁱ key₁ value₁ (+1 left) right ↦b = +1 (Node key₁ value₁ left right ↦l)
balance-leftⁱ key₁ value₁ (+1 (Node key₂ value₂ left₂ right₂ ↦l)) right₁ ↦l
  = +0 (Node key₂ value₂ left₂ (Node key₁ value₁ right₂ right₁ ↦b) ↦b)
balance-leftⁱ key₁ value₁ (+1 (Node key₂ value₂ left₂ right₂ ↦b)) right₁ ↦l
  = +1 (Node key₂ value₂ left₂ (Node key₁ value₁ right₂ right₁ ↦l) ↦r)
balance-leftⁱ key₁ value₁
  (+1 (Node key₂ value₂ left₂ (Node key₃ value₃ left₃ right₃ bal) ↦r)) right₁ ↦l
  = +0 (Node key₃ value₃
         (Node key₂ value₂ left₂ left₃ (∣h-l∣↦h bal))
         (Node key₁ value₁ right₃ right₁ (∣r-h∣↦h bal))
         ↦b)

balance-rightⁱ
  : ∀ {h-left h-right h}
      {l-bound r-bound}
      (key : Key)
    -> V key
    -> AVL l-bound [ key ] h-left
    -> Insert [ key ] r-bound h-right
    -> ∣ h-left - h-right ∣↦ h
    -> Insert l-bound r-bound (suc h)
balance-rightⁱ key₁ value₁ left₁ (+0 right₁) balance = +0 (Node key₁ value₁ left₁ right₁ balance)
balance-rightⁱ key₁ value₁ left₁ (+1 right₁) ↦l = +0 (Node key₁ value₁ left₁ right₁ ↦b)
balance-rightⁱ key₁ value₁ left₁ (+1 right₁) ↦b = +1 (Node key₁ value₁ left₁ right₁ ↦r)
balance-rightⁱ key₁ value₁ left₁ (+1 (Node key₂ value₂ left₂ right₂ ↦r)) ↦r
  = +0 (Node key₂ value₂ (Node key₁ value₁ left₁ left₂ ↦b) right₂ ↦b)
balance-rightⁱ key₁ value₁ left₁ (+1 (Node key₂ value₂ left₂ right₂ ↦b)) ↦r
  = +1 (Node key₂ value₂ (Node key₁ value₁ left₁ left₂ ↦r) right₂ ↦l)
--       1
--      / \
--     /   \
--    L1   2
--        / \
--       /   \
--      3    R2
--     / \
--    /   \
--    L3  R3
balance-rightⁱ key₁ value₁ left₁
  (+1 (Node key₂ value₂ (Node key₃ value₃ left₃ right₃ bal) right₂ ↦l)) ↦r
  = +0 (Node key₃ value₃
         (Node key₁ value₁ left₁ left₃ (∣h-l∣↦h bal))
         (Node key₂ value₂ right₃ right₂ (∣r-h∣↦h bal))
         ↦b)

insertWith
  : ∀ {h} {l-bound r-bound}
   -> (key : Key)
   -> V key
   -> (V key -> V key -> V key)
   -> l-bound < key < r-bound
   -> AVL l-bound r-bound h
   -> Insert l-bound r-bound h
insertWith key₁ value₁ update
  l-bound<key<r-bound (Leaf l-bound<r-bound)
  = +1 (singleton key₁ value₁ l-bound<key<r-bound)
insertWith key₁ value₁ update
  (l-bound<key <×< key<r-bound) (Node key₂ value₂ left₁ right₁ balance) with compare key₁ key₂
... | tri< key₁<key₂ _ _
    = balance-leftⁱ key₂ value₂ left₂ right₁ balance
    where left₂ = insertWith key₁ value₁ update (l-bound<key <×< [ key₁<key₂ ]) left₁
... | tri≈ _ key₁≡key₂ _ rewrite sym key₁≡key₂
    = +0 (Node key₁ (update value₁ value₂) left₁ right₁ balance)
... | tri> _ _ key₂<key₁
    = balance-rightⁱ key₂ value₂ left₁ right₂ balance
    where right₂ = insertWith key₁ value₁ update ([ key₂<key₁ ] <×< key<r-bound) right₁

balance-leftᵈ
  : ∀ {h-left h-right h}
      {l-bound r-bound}
      (key : Key)
    -> V key
    -> Insert l-bound [ key ] (pred h-left)
    -> AVL [ key ] r-bound h-right
    -> ∣ h-left - h-right ∣↦ h
    -> Insert l-bound r-bound h
balance-leftᵈ key₁ value₁ (+0 left₁) right₁ ↦l = +0 (Node key₁ value₁ left₁ right₁ ↦b)
balance-leftᵈ key₁ value₁ (+0 left₁) right₁ ↦b = +1 (Node key₁ value₁ left₁ right₁ ∣[h-1]-h∣↦h)
balance-leftᵈ key₁ value₁ (+0 left₁) (Node key₂ value₂ left₂ right₂ balance) ↦r
  = +1 (Node key₂ value₂ (Node key₁ value₁ left₁ left₂ {!!}) right₂ ↦l)
balance-leftᵈ key₁ value₁ (+1 x) right₁ balance = undefined

balance-rightᵈ
  : ∀ {h-left h-right h}
      {l-bound r-bound}
      (key : Key)
    -> V key
    -> AVL l-bound [ key ] h-left
    -> Insert [ key ] r-bound (pred h-right)
    -> ∣ h-left - h-right ∣↦ h
    -> Insert l-bound r-bound h
balance-rightᵈ = undefined

decrease-bound
  : ∀ {h} {l-bound m-bound r-bound}
   -> l-bound <ᵇ m-bound
   -> AVL m-bound r-bound h
   -> AVL l-bound r-bound h
decrease-bound l-bound<m-bound (Leaf m-bound<r-bound)
  = Leaf (<ᵇ-transitive l-bound<m-bound m-bound<r-bound)
decrease-bound l-bound<m-bound (Node key value left right balance)
  = Node key value (decrease-bound l-bound<m-bound left) right balance

balanceᵈ
   : ∀ {h-left h-right h}
       {l-bound m-bound r-bound}
    -> AVL l-bound m-bound h-left
    -> AVL m-bound r-bound h-right
    -> ∣ h-left - h-right ∣↦ h
    -> Insert l-bound r-bound h
balanceᵈ (Leaf l-bound<m-bound) right ↦b = +0 (decrease-bound l-bound<m-bound right)
balanceᵈ (Leaf l-bound<m-bound) right ↦r = +0 (decrease-bound l-bound<m-bound right)
balanceᵈ (Node key value left left₁ balance₁) right balance
  = balance-leftᵈ key value {!!} {!!} balance

delete
  : ∀ {h} {l-bound r-bound}
   -> (key : Key)
   -> AVL l-bound r-bound h
   -> Insert l-bound r-bound (pred h)
delete key (Leaf l-bound<r-bound) = +0 (Leaf l-bound<r-bound)
delete key (Node key₁ value₁ left₁ right₁ balance) with compare key key₁
... | tri< _ _ _ = balance-leftᵈ key₁ value₁ left₂ right₁ balance
    where left₂  = delete key left₁
... | tri≈ _ _ _ = balanceᵈ left₁ right₁ balance
... | tri> _ _ _ = balance-rightᵈ key₁ value₁ left₁ right₂ balance
    where right₂ = delete key right₁


