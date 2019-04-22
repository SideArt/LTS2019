module FreeGroup

import Monoid
import Group
import congruence

%access public export

||| The type of free groups generated by elements of a type
data FreeGroup : (typ : Type) -> Type where
    Iden : (typ : Type) -> (FreeGroup typ)
    Incl : typ -> (FreeGroup typ)
    Inv_incl : typ -> (FreeGroup typ)
    (*) : {typ : Type} -> (FreeGroup typ) -> (FreeGroup typ) -> (FreeGroup typ)

{-
data EqFree : {typ : Type} -> (FreeGroup typ) -> (FreeGroup typ) -> Type where
    same : {typ : Type} -> {a : (FreeGroup typ)} -> (EqFree a a)
    inv_eq : {typ : Type} -> {a : typ} -> ( EqFree (Incl a) (Inv_incl a) )
    assoc_eq : {typ : Type} -> (a, b, c : (FreeGroup typ)) -> ( EqFree ((a*b)*c) (a*(b*c)) )

Transport : {typ : Type} -> {P : (FreeGroup typ) -> Type} -> {a, b : (FreeGroup typ)} ->
            (EqFree a b) -> (P a) -> (P b)

Translation : {typ : Type} -> {a, b : (FreeGroup typ)} -> (EqFree a b) -> (a = b)
-}

||| Group axioms
id_eq : {typ : Type} -> (a : (FreeGroup typ)) -> ( a * (Iden typ)= a , (Iden typ) * a = a )
inv_eq : {typ : Type} -> (a : typ) -> ( (Incl a) * (Inv_incl a) = (Iden typ), (Inv_incl a) * (Incl a) = (Iden typ))
assoc_eq : {typ : Type} -> (a, b, c : (FreeGroup typ)) -> ( (a*b)*c  = a*(b*c) )

--total
||| A proof that each element of the free group has an inverse

FreeInverse : (typ : Type) -> (a : (FreeGroup typ)) -> ( b : (FreeGroup typ) ** ((a * b = (Iden typ)) , (b * a = (Iden typ))))
FreeInverse typ (Iden typ) = ((Iden typ) ** (id_eq (Iden typ)))
FreeInverse typ (Incl a) = ((Inv_incl a) ** (inv_eq a))
FreeInverse typ (a * b) = let

    a_inv_pf = FreeInverse typ a
    b_inv_pf = FreeInverse typ b
    a_inv = (fst a_inv_pf)
    b_inv = (fst b_inv_pf)
    a_pf = (snd a_inv_pf)
    b_pf = (snd b_inv_pf)
    pf1 = assoc_eq b b_inv a_inv
    pf2 = congruence (FreeGroup typ) (FreeGroup typ) (b * b_inv) (Iden typ) (\c => (c * a_inv)) (fst b_pf)
    pf3 = (snd (id_eq (a_inv)))
    pf4 = trans pf2 pf3
    pf5 = congruence (FreeGroup typ) (FreeGroup typ) ((b * b_inv) * a_inv) a_inv (\c => (a * c)) pf4
    pf6 = trans pf5 (fst a_pf)
    pf7 = assoc_eq a (b * b_inv) a_inv
    pf8 = assoc_eq a b b_inv
    pf9 = congruence (FreeGroup typ) (FreeGroup typ) ((a * b) * b_inv) (a * (b * b_inv)) (\c => (c * a_inv)) pf8
    pf10 = assoc_eq (a*b) b_inv a_inv
    pf11 = trans (sym pf10) pf9
    pf12 = trans pf11 pf7
    pf13 = trans pf12 pf6

    in
    ((b_inv * a_inv) ** (pf13, ?rhs))

{-
FreeGroup_is_Group : {typ : Type} -> (IsGroup (FreeGroup typ) (*))
FreeGroup_is_Group = ( assoc_eq , ((Iden ** (\b => (id_eq {a = b}))),
                                  ((Iden ** (\b => (id_eq {a = b}))) ** (\b => (?rhs)))))
-}