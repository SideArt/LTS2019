module Primes

import NatUtils
import gcd
import NatOrder
import Lists

%access public export
%default total

--isDiv a b can be constucted if b divides a
isDiv : (a : Nat) -> (b : Nat) -> ((b=0) -> Void) -> Type
isDiv a b pf = (n : Nat ** (a = b * n))

--Zero is divisible by anything
divZero : {n : Nat} -> {pf: ((n=0)->Void)} -> isDiv 0 n pf
divZero {n=Z} {pf=pf} = void (pf Refl)
divZero {n= (S k)} {pf = p} = (0 ** (rewrite (multCommutative Z (S k)) in Refl))

--1 divides everything
oneDiv : (a : Nat) -> {auto x : GT a 0} -> isDiv a 1 (SIsNotZ)
oneDiv a {x=pf} = (a ** (rewrite plusZeroRightNeutral a in Refl))

--If 1|a => 1*c | a*c
mulDiv : (a, c : Nat) -> {pf1 : ((a=0)->Void)} -> {pf2 : ((c=0) -> Void)} ->
  isDiv a 1 SIsNotZ -> isDiv (a * c) c pf2
mulDiv a c {pf1=p} x = (a ** (rewrite multCommutative a c in Refl))


--Either(a=b)(_) <=> Either (S a = S b)(_)
help1 : {a : Nat} -> {b : Nat} ->
  Either (a = b) (Either (LT (S a) (S b)) (LT (S b) (S a))) ->
  Either (S a = S b) (Either (LT (S a) (S b)) (LT (S b) (S a)))
help1 {a} {b} (Left l) = Left (eqSucc a b l)
help1 (Right r) = Right r

--Either(_)(Either(Sa<Sb)(_)) <=> Either (_)(Either(a<b)(_))
help2 : {a : Nat} -> {b : Nat} ->
  Either (a = b) (Either (LT a b) (LT (S b) (S a))) ->
  Either (a = b) (Either (LT (S a) (S b)) (LT (S b) (S a)))
help2 (Left l) = Left l
help2 {a} {b} (Right (Left l)) = Right(Left (LTESucc l))
help2 (Right (Right r)) = Right (Right r)

--Either(_)(Either(_)(Sb<Sa)) <=> Either (_)(Either(_)(b<a))
help3 : {a : Nat} -> {b : Nat} ->
  Either (a = b) (Either (LT a b) (LT b a)) ->
  Either (a = b) (Either (LT a b) (LT (S b) (S a)))
help3 (Left l) = Left l
help3 (Right (Left l)) = Right(Left l)
help3 {a} {b} (Right (Right r)) = Right (Right (LTESucc r))

|||Either a = b, a < b, or a > b
totOrdNat : (a : Nat) -> (b : Nat) ->
  Either (a = b) (Either (LT a b) (LT b a))
totOrdNat Z Z = Left Refl
totOrdNat Z (S k) = Right (Left (LTESucc LTEZero))
totOrdNat (S k) Z = Right (Right (LTESucc LTEZero))
totOrdNat (S k) (S j) = help1 (help2 (help3 (totOrdNat k j)))

--LTE a b => LTE a*n b*n
multRightLTE : (a,b : Nat) -> (n : Nat) -> GT n 0 ->
  LTE a b -> LTE (a*n) (b*n)
multRightLTE a b (S Z) (LTESucc LTEZero) lteab =
                            rewrite multOneRightNeutral a in
                            rewrite multOneRightNeutral b in
                            lteab
multRightLTE a b (S (S k)) (LTESucc LTEZero{right=(S k)}) lteab =
          rewrite multRightSuccPlus a (S k) in
          rewrite multRightSuccPlus b (S k) in
          ltePlusIsLTE lteab
          (multRightLTE a b (S k) (LTESucc LTEZero{right=k}) lteab)

--If a = b*n, b <= a
aEqProdImpAGtB : (a,b,n : Nat) -> GT n 0 -> (a = b*n) -> LTE b a
aEqProdImpAGtB _ _ Z LTEZero _ impossible
aEqProdImpAGtB _ _ Z (LTESucc _) _ impossible
aEqProdImpAGtB (b * (S k)) b (S k) x Refl = case b of
              Z => LTEZero
              (S m) =>
                rewrite sym (multOneLeftNeutral (S m)) in
                rewrite multCommutative (S m) (S k) in
                rewrite multDistributesOverPlusRight k (S Z) m in
                rewrite plusCommutative (k*1) (k*m) in
                rewrite plusAssociative m (k*m) (k*1) in
                rewrite plusCommutative (m + k*m) (k*1) in
                rewrite sym (multDistributesOverPlusRight (S k) 1 m) in
                multRightLTE 1 (S k) (S m) (LTESucc (LTEZero)) x

--If b | a => b <= a
bDivAImpAGtB : (a,b : Nat) -> (p : ((b=0) -> Void)) -> isDiv a b p -> Either (LTE b a)(a=0)
bDivAImpAGtB a Z p (x ** pf) = void (p Refl)
bDivAImpAGtB a (S k) p (x ** pf) = case a of
                  Z => Right Refl
                  (S j) => Left 

-- --GT implies Not LTE
-- gtImpliesNotLTE : GT a b -> Not (LTE a b)
-- gtImpliesNotLTE {a=Z} {b=_} LTEZero impossible
-- gtImpliesNotLTE {a=Z} {b=_} (LTESucc _) impossible
-- gtImpliesNotLTE {a=(S k)} {b=Z} x = case isLTE (S k) Z of
--                                  (Yes prf) => absurd
--                                  (No contra) => contra
-- gtImpliesNotLTE {a=(S k)} {b=(S j)} x = case isLTE (S k) (S j) of
--                                  (Yes prf) => void
--                                       (gtImpliesNotLTE (fromLteSucc x) (fromLteSucc prf))
--                                  (No contra) => contra
--
-- --If b > a => b does not divide a
-- bGtAImpNotbDivA : (a,b,n : Nat) -> GT b a -> (isDiv a b -> Void)
-- bGtAImpNotbDivA a b n x = impliesContrapositive
--                           (isDiv a b)
--                           (LTE b a)
--                           (bDivAImpAGtB a b n)
--                           (gtImpliesNotLTE x)
--
-- --(S (S k)) = 0 is not possible
-- zNotEqSS : (k : Nat) -> ((S (S k)) = 0 -> Void)
-- zNotEqSS Z = absurd
-- zNotEqSS (S k) = absurd
--
-- --isDiv p 0 => (S (S k)) = 0
-- help4 : (p : Nat) -> LTE 2 p -> isDiv p 0 -> p = 0
-- help4 Z LTEZero _ impossible
-- help4 Z (LTESucc _) _ impossible
-- help4 (S Z) (LTESucc LTEZero) _ impossible
-- help4 (S Z) (LTESucc (LTESucc _)) _ impossible
-- help4 (S (S k)) (LTESucc (LTESucc LTEZero)) x = snd (snd x)
--
--
-- --If x = 0, and p >= 2, x cannot divide p
-- zNotDivp : (p : Nat) -> LTE 2 p -> ((isDiv p 0) -> Void)
-- zNotDivp Z LTEZero impossible
-- zNotDivp Z (LTESucc _) impossible
-- zNotDivp (S Z) (LTESucc LTEZero) impossible
-- zNotDivp (S Z) (LTESucc (LTESucc _)) impossible
-- zNotDivp (S (S k)) (LTESucc (LTESucc LTEZero)) =
--                         impliesContrapositive
--                         (isDiv (S (S k)) 0)
--                         ((S (S k)) = 0)
--                         (help4 (S (S k)) (LTESucc (LTESucc LTEZero)))
--                         (zNotEqSS k)
--
-- -- Helping out metaHelp
-- metaMetaHelp5 : (j : Nat) -> (S (j+0)) = (S j)
-- metaMetaHelp5 Z = Refl
-- metaMetaHelp5 (S k) = rewrite plusZeroRightNeutral k in Refl
--
-- --Helping out help5
-- metaHelp5 : (S (S k)) = (S (j+0)) -> (S (S k)) = (S (j))
-- metaHelp5 {j} prf = rewrite sym (metaMetaHelp5 j) in prf
--
--
-- -- Helping out the absurd case
-- help5: (S (S k)) = (S (j+0)) -> LT (S j) (S (S k)) ->  LTE (S Z) 0
-- help5 {k} {j} prf x = lteMinusConstantRight {c=(S j)}
--             (rewrite sym (metaMetaHelp5 j) in
--              rewrite sym prf in
--              rewrite eqSucc (S (S k)) (S j) (metaHelp5 prf) in
--              x)
--
-- --If a divides b => b=a*n
-- bDivAImpBEqAN : (a,b : Nat) -> isDiv b a ->  (k : Nat ** b = a * k)
-- bDivAImpBEqAN a b (p ** (proofGT, proofEq)) = (p ** proofEq)
--
-- --To help out help6
-- metaHelp6 : (p : Nat) -> (x : Nat) -> (c : Nat) ->
--   (p = x*c) -> q = c -> (p = q*x)
-- metaHelp6 p x c prf prf1 = rewrite prf1 in
--                        rewrite multCommutative c x in prf
--
-- --To help out a case in notDivIfRem
-- help6 : (p : Nat) -> (x : Nat) -> (c : Nat) ->
--   (p = q*x) -> (p = (S r) + q*x) ->
--   (Z = (S r))
-- help6 p x c {q} {r} p1 p2 = plusRightCancel Z (S r) (q*x) (trans (sym p1) p2)
--
-- --To help out another case of notDivIfRem
-- help7 : (p : Nat) -> (x : Nat) -> (c : Nat) -> (k : Nat) -> (r : Nat) ->
--         c + k = q -> p = x*c -> p = (S r) + q*x ->
--         Z = (S r) + k*x
-- help7 p x c k r pfSum pfMul pfRem =
--           plusRightCancel Z ((S r)+k*x) (c*x)
--           (rewrite sym (plusAssociative (S r) (k*x) (c*x)) in
--            rewrite plusCommutative (k*x) (c*x) in
--            rewrite sym (multDistributesOverPlusLeft c k x) in
--            rewrite pfSum in
--            rewrite sym (multCommutative x c) in
--            rewrite sym (pfMul) in pfRem)
--
-- --Helper for help8
-- metahelp8 : (x : Nat) -> (S q) + k = c -> x +(q+k)*x = c*x
-- metahelp8 x prf = rewrite sym prf in Refl
--
-- --Last case!
-- help8 : (p : Nat) -> (x : Nat) -> (c : Nat) -> (k : Nat) ->
--         (m : Nat) -> (r : Nat) -> (q : Nat) ->
--         (S q) + k = c -> (S (S r)) + m = x -> p = x*c -> p = (S r) + q*x ->
--         Z = k*(S r) + (S k)*(S m)
-- help8 p x c k m r q qLtc srLtx pfMul pfRem =
--           plusLeftCancel (S r) Z (k*(S r) + (S k)*(S m))
--           (rewrite plusAssociative (S r) (k*(S r)) ((S k)*(S m)) in
--            rewrite sym (multDistributesOverPlusRight (S k) (S r) (S m)) in
--            rewrite plusAssociative r (S Z) m in
--            rewrite plusCommutative r (S Z) in
--            rewrite srLtx in
--            rewrite sym (plusCommutative (k*x) ((S (S r)) + m)) in
--            rewrite srLtx in
--            rewrite plusCommutative (k*x) x in
--            rewrite plusZeroRightNeutral r in
--            plusLeftCancel (q*x) (S r) (x + k*x)
--            (rewrite plusAssociative (q*x) x (k*x) in
--             rewrite plusCommutative (q*x) x in
--             rewrite sym (multDistributesOverPlusLeft (S q) k x) in
--             rewrite metahelp8 {q=q} {k=k} {c=c} x qLtc in
--             rewrite (multCommutative c x) in
--             rewrite sym pfMul in
--             rewrite plusCommutative (q*x) (S r) in
--             (sym pfRem)))
--
-- help9 : (k,r,m : Nat) ->
--         Z = k*(S r) + (S k)*(S m) -> Z = (S k)*(S m) + k*(S r)
-- help9 k r m prf = rewrite plusCommutative ((S k)*(S m)) (k*(S r)) in prf
--
-- --To help out the last case, by creating a term of an uninhabited type
-- notDivIfRem : (p : Nat) -> (x : Nat) -> (r : Nat) -> {q : Nat} ->
--   (p = (S r) + q*x) -> LT (S r) x ->
--   (c : Nat ** p = x * c) -> Void
-- notDivIfRem p x r {q=q} prfRem prfLt (c ** prfDiv) =
--     case decEq q c of
--         (Yes prf) => absurd $
--                       (help6 p x c (metaHelp6 p x c prfDiv prf) prfRem)
--         (No contra) => case totOrdNat q c of
--               (Left l) => void (contra l)
--               (Right (Left qLtc)) => case (lteToLEQ qLtc) of
--                         (k ** pf1) => case (lteToLEQ prfLt) of
--                           (m ** pf2) => absurd $
--                               help9 k r m
--                                 (help8 p x c k m r q pf1 pf2 prfDiv prfRem)
--               (Right (Right qGtc)) => case (lteToLEQ (lteSuccLeft qGtc)) of
--                           (k ** pf) => absurd $
--                               (help7 p x c k r pf prfDiv prfRem)
--
-- --The usual case for divisibility
-- usual : (p : Nat) -> LTE 2 p -> (x : Nat) -> (LT 0 x) -> (LT x p) ->
--   (euc : (q : Nat ** (r : Nat ** ((p = r + (q * x)), LT r x)))) ->
--   Dec (isDiv p x)
-- usual Z LTEZero _ _ _ _ impossible
-- usual Z (LTESucc _) _ _ _ _ impossible
-- usual (S Z) (LTESucc LTEZero) _ _ _ _ impossible
-- usual (S Z) (LTESucc (LTESucc _)) _ _ _ _ impossible
-- usual (S (S _)) (LTESucc (LTESucc LTEZero)) Z LTEZero _ _ impossible
-- usual (S (S _)) (LTESucc (LTESucc LTEZero)) Z (LTESucc _) _ _ impossible
-- usual (S (S k)) (LTESucc (LTESucc LTEZero))
--       (S j) (LTESucc LTEZero)
--       xLtp euc with (euc)
--         usual (S (S k)) (LTESucc (LTESucc LTEZero))
--               (S j) (LTESucc LTEZero)
--               xLtp euc | (Z ** (Z ** (pf,_))) = absurd $ pf
--
--         usual (S (S k)) (LTESucc (LTESucc LTEZero))
--               (S j) (LTESucc LTEZero)
--               xLtp euc | ((S Z) ** (Z ** (pf,_))) = absurd $
--                       (help5 pf xLtp)
--
--         usual (S (S k)) (LTESucc (LTESucc LTEZero))
--               (S j) (LTESucc LTEZero)
--               xLtp euc | ((S (S b)) ** (Z ** (pf,_))) =
--                 Yes ((S (S b)) ** ((LTESucc LTEZero),
--                                     (rewrite multCommutative (S j) (S (S b)) in pf)))
--
--         usual (S (S k)) (LTESucc (LTESucc LTEZero))
--               (S j) (LTESucc LTEZero)
--               xLtp euc | (_ ** ((S a) ** (pf1,pf2))) = No
--                               (impliesContrapositive
--                                 (isDiv (S (S k)) (S j))
--                                 (c : Nat ** (S (S k)) = (S j) * c)
--                                 (bDivAImpBEqAN (S j) (S (S k)))
--                                 (notDivIfRem (S (S k)) (S j) a pf1 pf2))
--
--
-- --Decidability for divisibility
-- decDiv : (p : Nat) -> LTE 2 p -> (x : Nat) ->
--   {euc : (q : Nat ** (r : Nat ** ((p = r + (q * x)), LT r x)))} ->
--   Dec (isDiv p x)
-- decDiv Z LTEZero _ impossible
-- decDiv Z (LTESucc _) _ impossible
-- decDiv (S Z) (LTESucc LTEZero) _ impossible
-- decDiv (S Z) (LTESucc (LTESucc _)) _ impossible
-- decDiv (S (S k)) (LTESucc (LTESucc LTEZero)) x {euc=big} =
--     case totOrdNat (S (S k)) x of
--       (Left l) => Yes (1 ** ((LTESucc LTEZero),
--                              rewrite l in
--                              rewrite sym (multOneRightNeutral x) in
--                              Refl))
--       (Right (Left l)) => No (bGtAImpNotbDivA
--                               (S (S k)) x
--                               (divNatNZ x (S (S k)) SIsNotZ)
--                               l)
--       (Right (Right r)) => case x of
--           Z => No (zNotDivp (S (S k)) (LTESucc (LTESucc LTEZero)))
--           (S m) => usual (S (S k)) (LTESucc (LTESucc LTEZero)) (S m)
--                    (LTESucc LTEZero) r big
--
--
-- -- creates a list with all the factors of a number upto the second arguement
-- genFact : (n : Nat) -> Nat -> List (k : Nat ** isDiv n k)
-- genFact Z Z = []
-- genFact Z (S k) = []
-- genFact (S j) Z = []
-- genFact (S Z) (S k) = [(S Z ** oneDiv (S Z))]
-- genFact (S (S j)) (S k) =
--     case (decDiv (S (S j)) (LTESucc (LTESucc (LTEZero{right = j}))) (S k)
--           {euc=euclidDivide (S (S j)) (S k) SIsNotZ }) of
--                (Yes prf) => (genFact (S (S j)) k) ++ [(S k ** prf)]
--                (No contra) => (genFact (S (S j)) k)
--
--
-- isDivImpInList : (n : Nat) -> (k : Nat) -> (pf : isDiv n k) -> isElementOfList (k : Nat ** isDiv n k) (genFact n n) (k ** pf)
-- isDivImpInList n k pf = ?isDivImpInList_rhs
--
--
--
-- --if the List has only 2 elements, i.e 1 and p, then the number is prime. the function outputs a list (secretly genFact)
-- -- along with the proof that the length of the list of factors is 2
-- isPrimeCalc : (p: Nat) -> {auto pf: LTE 2 p} -> Type
-- isPrimeCalc p = (length (genFact p p) = 2)
--
-- -- more than 2 factors implies number is composite
-- isCompositeCalc : (n: Nat) -> {auto pf: LTE 2 n} -> Type
-- isCompositeCalc n = Prelude.Nat.GT (Prelude.List.length (genFact n n)) 2
--
-- --prime proof
-- isPrime : (p : Nat) -> LTE 2 p -> Type
-- isPrime p proofLTE = {k : Nat} -> isDiv p k -> Either (k=1)(k=p)
--
--
--
-- -- Two is a prime
-- twoPr : (isPrime 2 (LTESucc (LTESucc (LTEZero {right =0}))))
-- twoPr {k=Z} (x ** pf) = void (SIsNotZ (snd pf))
-- twoPr {k=(S Z)} (x ** pf) = Left Refl
-- twoPr {k=(S (S Z))} (x ** pf) = Right Refl
-- twoPr {k=(S (S (S k)))} pf = void (bGtAImpNotbDivA 2 (S (S (S k))) k (LTESucc (LTESucc (LTESucc (LTEZero {right = k})))) (pf))
--
-- --Composite proof
-- isComposite : (n : Nat) -> LTE 2 n -> Type
-- isComposite n pflte = (a : Nat ** (b : Nat ** ((GT a 1, GT b 1), n = a*b)))
--
--
-- --deciability for Composite numbers
-- decComposite : (n: Nat) -> (pf : LTE 2 n) -> Dec (isComposite n pf)
-- decComposite Z LTEZero impossible
-- decComposite Z (LTESucc _) impossible
-- decComposite (S Z) (LTESucc LTEZero) impossible
-- decComposite (S Z) (LTESucc (LTESucc _)) impossible
-- decComposite (S (S k)) pf = ?decCompositerhs_1
--
--
--
--
-- --if 1<n, a not equal to a*n
-- aNotEqToMultA : (a : Nat) -> LTE 1 a -> (n : Nat) -> LTE 2 n -> (a = a*n) -> Void
-- aNotEqToMultA _ _ Z LTEZero _ impossible
-- aNotEqToMultA _ _ Z (LTESucc _) _ impossible
-- aNotEqToMultA _ _ (S Z) (LTESucc LTEZero) _ impossible
-- aNotEqToMultA _ _ (S Z) (LTESucc (LTESucc _)) _ impossible
-- aNotEqToMultA Z LTEZero (S (S _)) _ _ impossible
-- aNotEqToMultA Z (LTESucc _) (S (S _)) _ _ impossible
-- aNotEqToMultA (S j) (LTESucc (LTEZero {right = j})) (S (S k)) (LTESucc (LTESucc (LTEZero {right = k}))) prf =
--                               SIsNotZ {x = j+(k*(S j))} (sym (pfeq)) where
--                                 pfeq  = plusLeftCancel (S j) Z ((S k)*(S j)) pfeq1 where
--                                   pfeq1 = rewrite (multCommutative (S (S k)) (S j)) in
--                                           trans (plusZeroRightNeutral (S j)) prf
--
-- --helper apNat function
-- apNat : (f: Nat -> Nat) -> (n: Nat) -> (m: Nat) -> n = m -> f n = f m
-- apNat f m m Refl = Refl
--
-- --n is not both prime and composite
-- notBothPrimeandComp : {n : Nat} -> (pf : LTE 2 n) -> Not (isPrime n pf, isComposite n pf)
-- notBothPrimeandComp {n = Z} LTEZero _ impossible
-- notBothPrimeandComp {n = Z} (LTESucc _) _ impossible
-- notBothPrimeandComp {n = (S Z)} (LTESucc LTEZero) _ impossible
-- notBothPrimeandComp {n = (S Z)} (LTESucc (LTESucc _)) _ impossible
-- notBothPrimeandComp {n = (S (S k))} pftwolten (pfprime , (a ** (b ** ((pfagtone, pfbgtone), pfneqab)))) =
--                             void (aNotEqToMultA (S (S k)) (lteTransitive (LTESucc (LTEZero {right = (S Z)})) pftwolten) b pfbgtone pfeq) where
--                               pfeq = (trans pfneqab funceq) where
--                                 funceq = (apNat (\x=>(x*b)) a (S (S k)) pfaeqn) where
--                                   pfaeqn =  case (pfprime (b ** ((lteTransitive (LTESucc (LTEZero {right = (S Z)})) pfbgtone), pfneqab))) of
--                                           Left pf => void ((Prelude.Basics.fst (ltImpliesNotEqNotGT {a=(S Z)} {b = a} pfagtone)) (sym pf))
--                                           Right pf => pf
--
-- -- given n >= 2, it is either prime or Composite
-- eitherPrimeOrComp : {n : Nat} -> (pf : LTE 2 n) -> Either (isPrime n pf)(isComposite n pf)
-- eitherPrimeOrComp {n = Z} LTEZero impossible
-- eitherPrimeOrComp {n = Z} (LTESucc _) impossible
-- eitherPrimeOrComp {n = (S Z)} (LTESucc LTEZero) impossible
-- eitherPrimeOrComp {n = (S Z)} (LTESucc (LTESucc _)) impossible
-- eitherPrimeOrComp {n = (S (S k))} pflte = ?rhs_1
--
--   -- data Prime : (p : Nat) -> Type where
--   --  IsPrime : LTE 2 p -> ((k : Nat) -> isDiv p k -> Either (k=1)(k=p)) -> Prime p
--
--   -- function to check that 2 is prime
--   -- twoPr : (k : Nat) -> (isDiv 2 k) -> Either (k = 1)(k = 2)
--   -- twoPr Z (x ** pf) = void (SIsNotZ (snd pf))
--   -- twoPr (S Z) (x ** pf) = Left Refl
--   -- twoPr (S (S Z)) (x ** pf) = Right Refl
--   -- twoPr (S (S (S k))) pf = void (bGtAImpNotbDivA 2 (S (S (S k))) k (LTESucc (LTESucc (LTESucc (LTEZero {right = k})))) (pf))
--   --
--   -- --two is Prime
--   -- twoIsPrime : Prime 2
--   -- twoIsPrime = IsPrime (LTESucc (LTESucc (LTEZero {right =0}))) twoPr
--
--
-- -- notBothPrimeandComp Z LTEZero _ _ impossible
-- -- notBothPrimeandComp Z (LTESucc _) _ _ impossible
-- -- notBothPrimeandComp (S Z) (LTESucc LTEZero) _ _ impossible
-- -- notBothPrimeandComp (S Z) (LTESucc (LTESucc _)) _ _ impossible
-- -- notBothPrimeandComp (S (S k)) pfgt pfprime pfcomp = ?jk
--
--
--
--
--
-- --same as oneDiv, but fits the format for the following functions
-- -- oneIsFactor : (n : Nat) -> (LTE 1 n) -> (fromMaybe 0 (head' (List Nat)) = (S Z))
-- -- oneIsFactor Z LTEZero impossible
-- -- oneIsFactor Z (LTESucc _) impossible
-- -- oneIsFactor (S k) pf =
-- --
-- -- -- n is the last element of the list of its factors
-- -- nIsFactor : (n : Nat) -> (LTE 1 n) -> (fromMaybe 0 (tail' (genFact n n)) = n)
-- -- nIsFactor Z LTEZero impossible
-- -- nIsFactor Z (LTESucc _) impossible
-- -- nIsFactor (S k) pf = Refl
--
--
-- --Spare code
-- {-
-- --Type for isPrime. A number p is prime if all numbers dividing
-- --it are either p or 1. (In the primality checker, I am checking
-- --for numbers until p, hence the p case is not included. Will
-- --be changed in a future update.)
-- isPrime : Nat -> Type
-- isPrime p = (LTE 2 p ,
--             (x : Nat **
--             (isDiv p x , x = 1)))
-- --Does the job, but is not very useful. Will be replaced later.
-- checkPrime : (p : Nat) -> LTE 2 p -> {default (p-1) iter : Nat} ->
--   Maybe (isPrime p)
-- checkPrime p pf {iter=Z} = Nothing
-- checkPrime p pf {iter=(S Z)} = Just (pf, ((S Z) ** (oneDiv p, Refl)))
-- checkPrime p pf {iter=(S k)} = case modNatNZ p (S k) SIsNotZ of
--                             Z => Nothing
--                             (S m) => checkPrime p pf {iter=k}
-- -}
