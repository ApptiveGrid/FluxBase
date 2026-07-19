Class {
	#name : 'FBTestTaskWithBehavior',
	#superclass : 'FBTask',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'testing' }
FBTestTaskWithBehavior class >> isAbstract [

	^ true
]

{ #category : 'accessing' }
FBTestTaskWithBehavior >> defaultBehaviorClass [
	^ FBTestTaskBehavior 
]

{ #category : 'accessing' }
FBTestTaskWithBehavior >> value [
	^ 10 atRandom 
]
