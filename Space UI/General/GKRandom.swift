//
//  GKRandomDistribution.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2020-01-16.
//  Copyright © 2020 256 Arts Developer. All rights reserved.
//

import GameplayKit

struct WeightedElement<E> {
    let weight: Double
    let element: E
}

struct WeightedDesignElement<E> {
    let baseWeight: Double
    let design: DesignPrinciples
    let element: E
}

extension GKRandom {
    
    func nextInt(in range: Range<Int>) -> Int {
        range.lowerBound + nextInt(upperBound: range.upperBound - range.lowerBound)
    }
    func nextInt(in range: ClosedRange<Int>) -> Int {
        range.lowerBound + nextInt(upperBound: range.upperBound+1 - range.lowerBound)
    }
    
    func nextDouble(in range: Range<Double>) -> Double {
        Double(nextInt(in: Int(range.lowerBound*1000)..<Int(range.upperBound*1000)))/1000.0
    }
    func nextDouble(in range: ClosedRange<Double>) -> Double {
        Double(nextInt(in: Int(range.lowerBound*1000)...Int(range.upperBound*1000)))/1000.0
    }
    
    func nextFraction() -> Double {
        return Double(nextInt(upperBound: 1000))/1000.0
    }
    
    func nextBool(chance: Double) -> Bool {
        nextFraction() < chance
    }
    
    func nextElement<E>(in array: [E]) -> E? {
        guard !array.isEmpty else { return nil }
        return array[nextInt(upperBound: array.count)]
    }
    
    func nextWeightedElement<E>(in array: [WeightedElement<E>]) -> E? {
        guard !array.isEmpty else { return nil }
        
        let total = array.reduce(0, { $0 + $1.weight })
        let randomValue = nextDouble(in: 0..<total)
        
        var currentValue = 0.0
        for weightedElement in array {
            currentValue += weightedElement.weight
            if randomValue <= currentValue {
                return weightedElement.element
            }
        }
        return array[0].element
    }
    
    func nextWeightedElement<E>(in array: [WeightedDesignElement<E>], with design: DesignPrinciples) -> E? {
        let newElements = array.map {
            let similarity = $0.design.similarity(to: design)
            return WeightedElement(weight: $0.baseWeight * similarity, element: $0.element)
        }
        return nextWeightedElement(in: newElements)
    }
    
}
