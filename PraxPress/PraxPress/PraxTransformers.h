//
//  PraxTransformers.h
//  PraxPress
//
//  Created by John Canfield on 8/18/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Asset.h"

@interface PraxTransformers : NSObject
+(void)load;
@end

@interface PraxNumberIsZeroTransformer : NSValueTransformer
@end

@interface PraxNumberIsNotZeroTransformer : NSValueTransformer
@end

@interface PraxAssetStringTransformer : NSValueTransformer
@end
