Class {
	#name : 'FBSystemErrorTestTask',
	#superclass : 'FBTask',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'testing' }
FBSystemErrorTestTask class >> isAbstract [

	^ true
]

{ #category : 'accessing' }
FBSystemErrorTestTask >> value [
	^ 1/0
]
