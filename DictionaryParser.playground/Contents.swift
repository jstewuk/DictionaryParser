//: Playground - noun: a place where people can play

import UIKit

var str = "Hello, playground"

/**
 Need to build something that will make constructing an item from a dictionary of parameters that are optional (may not be present)
 If any of the required parameters for the constructor aren't in the dictionary, need to bail and return .None
 
 In Haskell one approach using applicatives is:
 userFromParams' :: Params -> Maybe User'
 userFromParams' params = User'
 <$> getParam "name" params
 <*> getParam "email" params
 
 where <$> is fmap :: (a -> b) - f a -> f b, 
 
 and f is a context or wrapping function like optional or array
 
 does swift have fmap?
 
 not directly but there are a few implementations on line
*/

extension Optional {
    func fmap<B>(f: (Wrapped -> B)) -> B? {
        guard let value = self else { return nil }
        return f(value)
    }
    
    func apply<B>(f: (Wrapped -> B)?) -> B? {
        guard let value = self, fn = f else { return nil }
        return fn(value)
    }
    
}

let sInt: Optional<Int> = 4
let nInt: Optional<Int> = nil

let f: (Int -> Int) = { $0 + 2 }

sInt.fmap(f)
nInt.fmap(f)

// Make it into <^> since <$> doens't work in swift
// argh.. operators have to be global

infix operator <^> { associativity left }

func <^><A, B>(lhs: (A -> B), rhs: A?) -> B? {
    return rhs.fmap(lhs)
}

f <^> sInt
f <^> nInt

infix operator <*> { associativity left }
func <*><A, B>(lhs: (A-> B)?, rhs: A?) -> B? {
    return rhs.apply(lhs)
}

let sf: (Int -> Int)? = Optional.Some(f)
let nf: (Int -> Int)? = Optional.None

sf <*> sInt
sf <*> nInt
nf <*> sInt
nf <*> nInt

// can we make it work with a parameter dictionary 
let params = ["a":"A", "b":"B", "c":"C", "d": "D"]

func getParam(name: String, params: [String:String]) -> String? {
    return params[name]
}

getParam("a", params: params)
getParam("d", params: params)

struct Thing {
    let a: String
    let b: String
    let c: String
    let d: String
}

// need to be able to curry the initializer: so from: https://github.com/thoughtbot/Argo/blob/master/Argo/Functions/curry.swift
func curry<T, U, V>(f : (T, U) -> V) -> T -> U -> V {
    return { x in { y in f(x, y) } }
}

// but that one only works for 2 params, we have 4

// for 3
func curry<T,U,V,W>(f: (T,U,V) -> W) -> T -> U -> V -> W {
    return { t in { u in { v in f(t,u,v)}}}
}
// 4
func curry<T,U,V,W,X>(f: (T,U,V,W) -> X) -> T -> U -> V -> W -> X {
    return { t in { u in { v in { w in f(t,u,v,w)}}}}
}
// 5
func curry<S,T,U,V,W,X>(f: (S,T,U,V,W)->X) -> S -> T -> U -> V -> W -> X {
    return { s in { t in { u in { v in { w in f(s,t,u,v,w)}}}}}
}

// nice that we can overload the function name!

curry(Thing.init)

extension Thing {
    static func decode(params: [String:String]) -> Thing? {
        return curry(Thing.init)                // (T) -> ((T) -> ((T) -> ((T) -> Thing))), T represents String
            <^> getParam("a", params: params)   // fmap ((T) -> ((T) -> ((T) -> ((T) -> Thing)))) onto getParam("a"..) => ((T) -> ((T) -> ((T) -> Thing)))?
            <*> getParam("b", params: params)   // apply ((T) -> ((T) -> ((T) -> Thing)))? to getParam("b"...) => ((T) -> ((T) -> Thing))?
            <*> getParam("c", params: params)   // apply ((T) -> ((T) -> Thing))? to getParam("c"...) => ((T) -> Thing)?
            <*> getParam("d", params: params)   // apply ((T) -> Thing)? to getParam("d"...) => Thing?
    }
}

// <^> => fmap  :: ((A -> B), A?) -> B?  => the optional wrapper around A is lifted to the result
// <*> => apply :: ((A -> B)?, A?) -> B? => lifts optional from either the function or the parameter to the result
// We use <^> to consume the first parameter because we don't expect a f? from currying Thing.init
// Use <*> to consume the rest of the parameters because the result of the previous operation is an optional function

Thing.decode(params)

let myThing = Thing.decode(["a":"A", "b":"B", "d": "D", "c":"C"])
myThing?.a
myThing?.b
myThing?.c
myThing?.d

Thing.decode(["a":"A", "b":"B", "d": "D"])

// what if I want my model objects to be dumb... does decode have to live in Thing?

func thingDecode(params: [String:String]) -> Thing? {
    return curry(Thing.init)
    <^> getParam("a", params: params)
    <*> getParam("b", params: params)
    <*> getParam("c", params: params)
    <*> getParam("d", params: params)
}

thingDecode(params)
