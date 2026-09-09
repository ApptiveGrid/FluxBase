Class {
	#name : 'FBTestTask',
	#superclass : 'FBTask',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'testing' }
FBTestTask class >> isAbstract [

	^ true
]

{ #category : 'accessing' }
FBTestTask >> producedValue [
	^ 10 atRandom 
]
