//
//  PraxTransformers.h
//  PraxPress
//
//  Created by John Canfield on 8/18/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Document.h"
#import "Asset.h"
#import "Tag.h"

@class Document;

@interface PraxTransformers : NSObject
+(void)loadForDocument:(Document *)document;
@end

@interface PraxPredicateToStringTransformer : NSValueTransformer
@end

@interface PraxNumberIsZeroTransformer : NSValueTransformer
@end

@interface PraxNumberIsNotZeroTransformer : NSValueTransformer
@end

@interface PraxNumberIsGreaterThanOneTransformer : NSValueTransformer
@end

@interface PraxAssetStringTransformer : NSValueTransformer
@end

@interface PraxAssetTagStringTransformer : NSValueTransformer {
    Document *_document;
}
@property Document *document;
@end
