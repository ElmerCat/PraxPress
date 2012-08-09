//
//  Track.h
//  PraxPress
//
//  Created by John Canfield on 7/30/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Track : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * artwork_url;
@property (nonatomic, retain) NSString * uri;
@property (nonatomic, retain) NSNumber * asset_id;
@property Boolean info_mode;
@property (nonatomic, retain) NSManagedObject *account;

@end


/*
 
 
 

<7b226b69 6e64223a 22747261 636b222c 22696422 3a353432 34373030 392c2263 72656174 65645f61 74223a22 32303132 2f30372f 32372030 343a3231 3a323320 2b303030 30222c22 75736572 5f696422 3a333636 32313138 2c226475 72617469 6f6e223a 32323133 332c2263 6f6d6d65 6e746162 6c65223a 74727565 2c227374 61746522 3a226669 6e697368 6564222c 226f7269 67696e61 6c5f636f 6e74656e 745f7369 7a65223a 33353331 37342c22 73686172 696e6722 3a227075 626c6963 222c2274 61675f6c 69737422 3a22222c 22706572 6d616c69 6e6b223a 226b6774 6e6a6d78 622d7269 6e676261 636b222c 22737472 65616d61 626c6522 3a747275 652c2265 6d626564 6461626c 655f6279 223a2261 6c6c222c 22646f77 6e6c6f61 6461626c 65223a74 7275652c 22707572 63686173 655f7572 6c223a22 68747470 3a2f2f65 6c6d6572 6361742e 6f72672f 70686f6e 652f6275 696c6469 6e67732f 6b67746e 6a6d7862 222c226c 6162656c 5f696422 3a6e756c 6c2c2270 75726368 6173655f 7469746c 65223a22 56697274 75616c20 50686f6e 65205472 6970222c 2267656e 7265223a 2250686f 6e65222c 22746974 6c65223a 224b696e 6773746f 6e2c204a 616d6169 6361204b 47544e4a 4d584220 2d205c22 52696e67 6261636b 20546f6e 655c2220 28666162 756c6f75 73207669 6e746167 65207465 6c657068 6f6e652f 63617272 69657220 736f756e 64732922 2c226465 73637269 7074696f 6e223a22 222c226c 6162656c 5f6e616d 65223a22 222c2272 656c6561 7365223a 22222c22 74726163 6b5f7479 7065223a 22726563 6f726469 6e67222c 226b6579 5f736967 6e617475 7265223a 22222c22 69737263 223a2222 2c227669 64656f5f 75726c22 3a6e756c 6c2c2262 706d223a 6e756c6c 2c227265 6c656173 655f7965 6172223a 6e756c6c 2c227265 6c656173 655f6d6f 6e746822 3a6e756c 6c2c2272 656c6561 73655f64 6179223a 6e756c6c 2c226f72 6967696e 616c5f66 6f726d61 74223a22 6d703322 2c226c69 63656e73 65223a22 616c6c2d 72696768 74732d72 65736572 76656422 2c227572 69223a22 68747470 733a2f2f 6170692e 736f756e 64636c6f 75642e63 6f6d2f74 7261636b 732f3534 32343730 3039222c 22757365 72223a7b 22696422 3a333636 32313138 2c226b69 6e64223a 22757365 72222c22 7065726d 616c696e 6b223a22 656c6d65 72636174 222c2275 7365726e 616d6522 3a22456c 6d657243 6174222c 22757269 223a2268 74747073 3a2f2f61 70692e73 6f756e64 636c6f75 642e636f 6d2f7573 6572732f 33363632 31313822 2c227065 726d616c 696e6b5f 75726c22 3a226874 74703a2f 2f736f75 6e64636c 6f75642e 636f6d2f 656c6d65 72636174 222c2261 76617461 725f7572 6c223a22 68747470 733a2f2f 69312e73 6e646364 6e2e636f 6d2f6176 61746172 732d3030 30303032 39353838 33322d78 786d6f6a 612d6c61 7267652e 6a70673f 64363939 35383722 7d2c2275 7365725f 706c6179 6261636b 5f636f75 6e74223a 312c2275 7365725f 6661766f 72697465 223a6661 6c73652c 22706572 6d616c69 6e6b5f75 726c223a 22687474 703a2f2f 736f756e 64636c6f 75642e63 6f6d2f65 6c6d6572 6361742f 6b67746e 6a6d7862 2d72696e 67626163 6b222c22 61727477 6f726b5f 75726c22 3a226874 7470733a 2f2f6931 2e736e64 63646e2e 636f6d2f 61727477 6f726b73 2d303030 30323733 39373138 302d7275 34336134 2d6c6172 67652e6a 70673f64 36393935 3837222c 22776176 65666f72 6d5f7572 6c223a22 68747470 733a2f2f 77312e73 6e646364 6e2e636f 6d2f7145 4e66764d 314b5559 4c705f6d 2e706e67 222c2273 74726561 6d5f7572 6c223a22 68747470 733a2f2f 6170692e 736f756e 64636c6f 75642e63 6f6d2f74 7261636b 732f3534 32343730 30392f73 74726561 6d222c22 646f776e 6c6f6164 5f75726c 223a2268 74747073 3a2f2f61 70692e73 6f756e64 636c6f75 642e636f 6d2f7472 61636b73 2f353432 34373030 392f646f 776e6c6f 6164222c 22706c61 79626163 6b5f636f 756e7422 3a332c22 646f776e 6c6f6164 5f636f75 6e74223a 302c2266 61766f72 6974696e 67735f63 6f756e74 223a302c 22636f6d 6d656e74 5f636f75 6e74223a 302c2261 74746163 686d656e 74735f75 7269223a 22687474 70733a2f 2f617069 2e736f75 6e64636c 6f75642e 636f6d2f 74726163 6b732f35 34323437 3030392f 61747461 63686d65 6e747322 2c227365 63726574 5f746f6b 656e223a 22732d72 53753479 222c2273 65637265 745f7572 69223a22 68747470 733a2f2f 6170692e 736f756e 64636c6f 75642e63 6f6d2f74 7261636b 732f3534 32343730 30393f73 65637265 745f746f 6b656e3d 732d7253 75347922 2c22646f 776e6c6f 6164735f 72656d61 696e696e 67223a31 3030307d>
 
 <3c3f786d 6c207665 7273696f 6e3d2231 2e302220 656e636f 64696e67 3d225554 462d3822 3f3e0a3c 74726163 6b3e0a20 203c6b69 6e643e74 7261636b 3c2f6b69 6e643e0a 20203c69 64207479 70653d22 696e7465 67657222 3e353432 34373030 393c2f69 643e0a20 203c6372 65617465 642d6174 20747970 653d2264 61746574 696d6522 3e323031 322d3037 2d323754 30343a32 313a3233 5a3c2f63 72656174 65642d61 743e0a20 203c7573 65722d69 64207479 70653d22 696e7465 67657222 3e333636 32313138 3c2f7573 65722d69 643e0a20 203c6475 72617469 6f6e2074 7970653d 22696e74 65676572 223e3232 3133333c 2f647572 6174696f 6e3e0a20 203c636f 6d6d656e 7461626c 65207479 70653d22 626f6f6c 65616e22 3e747275 653c2f63 6f6d6d65 6e746162 6c653e0a 20203c73 74617465 3e66696e 69736865 643c2f73 74617465 3e0a2020 3c6f7269 67696e61 6c2d636f 6e74656e 742d7369 7a652074 7970653d 22696e74 65676572 223e3335 33313734 3c2f6f72 6967696e 616c2d63 6f6e7465 6e742d73 697a653e 0a20203c 73686172 696e673e 7075626c 69633c2f 73686172 696e673e 0a20203c 7461672d 6c697374 3e3c2f74 61672d6c 6973743e 0a20203c 7065726d 616c696e 6b3e6b67 746e6a6d 78622d72 696e6762 61636b3c 2f706572 6d616c69 6e6b3e0a 20203c73 74726561 6d61626c 65207479 70653d22 626f6f6c 65616e22 3e747275 653c2f73 74726561 6d61626c 653e0a20 203c656d 62656464 61626c65 2d62793e 616c6c3c 2f656d62 65646461 626c652d 62793e0a 20203c64 6f776e6c 6f616461 626c6520 74797065 3d22626f 6f6c6561 6e223e74 7275653c 2f646f77 6e6c6f61 6461626c 653e0a20 203c7075 72636861 73652d75 726c3e68 7474703a 2f2f656c 6d657263 61742e6f 72672f70 686f6e65 2f627569 6c64696e 67732f6b 67746e6a 6d78623c 2f707572 63686173 652d7572 6c3e0a20 203c6c61 62656c2d 6964206e 696c3d22 74727565 223e3c2f 6c616265 6c2d6964 3e0a2020 3c707572 63686173 652d7469 746c653e 56697274 75616c20 50686f6e 65205472 69703c2f 70757263 68617365 2d746974 6c653e0a 20203c67 656e7265 3e50686f 6e653c2f 67656e72 653e0a20 203c7469 746c653e 4b696e67 73746f6e 2c204a61 6d616963 61204b47 544e4a4d 5842202d 20225269 6e676261 636b2054 6f6e6522 20286661 62756c6f 75732076 696e7461 67652074 656c6570 686f6e65 2f636172 72696572 20736f75 6e647329 3c2f7469 746c653e 0a20203c 64657363 72697074 696f6e3e 3c2f6465 73637269 7074696f 6e3e0a20 203c6c61 62656c2d 6e616d65 3e3c2f6c 6162656c 2d6e616d 653e0a20 203c7265 6c656173 653e3c2f 72656c65 6173653e 0a20203c 74726163 6b2d7479 70653e72 65636f72 64696e67 3c2f7472 61636b2d 74797065 3e0a2020 3c6b6579 2d736967 6e617475 72653e3c 2f6b6579 2d736967 6e617475 72653e0a 20203c69 7372633e 3c2f6973 72633e0a 20203c76 6964656f 2d75726c 206e696c 3d227472 7565223e 3c2f7669 64656f2d 75726c3e 0a20203c 62706d20 6e696c3d 22747275 65223e3c 2f62706d 3e0a2020 3c72656c 65617365 2d796561 72206e69 6c3d2274 72756522 3e3c2f72 656c6561 73652d79 6561723e 0a20203c 72656c65 6173652d 6d6f6e74 68206e69 6c3d2274 72756522 3e3c2f72 656c6561 73652d6d 6f6e7468 3e0a2020 3c72656c 65617365 2d646179 206e696c 3d227472 7565223e 3c2f7265 6c656173 652d6461 793e0a20 203c6f72 6967696e 616c2d66 6f726d61 743e6d70 333c2f6f 72696769 6e616c2d 666f726d 61743e0a 20203c6c 6963656e 73653e61 6c6c2d72 69676874 732d7265 73657276 65643c2f 6c696365 6e73653e 0a20203c 7572693e 68747470 733a2f2f 6170692e 736f756e 64636c6f 75642e63 6f6d2f74 7261636b 732f3534 32343730 30393c2f 7572693e 0a20203c 75736572 3e0a2020 20203c69 64207479 70653d22 696e7465 67657222 3e333636 32313138 3c2f6964 3e0a2020 20203c6b 696e643e 75736572 3c2f6b69 6e643e0a 20202020 3c706572 6d616c69 6e6b3e65 6c6d6572 6361743c 2f706572 6d616c69 6e6b3e0a 20202020 3c757365 726e616d 653e456c 6d657243 61743c2f 75736572 6e616d65 3e0a2020 20203c75 72693e68 74747073 3a2f2f61 70692e73 6f756e64 636c6f75 642e636f 6d2f7573 6572732f 33363632 3131383c 2f757269 3e0a2020 20203c70 65726d61 6c696e6b 2d75726c 3e687474 703a2f2f 736f756e 64636c6f 75642e63 6f6d2f65 6c6d6572 6361743c 2f706572 6d616c69 6e6b2d75 726c3e0a 20202020 3c617661 7461722d 75726c3e 68747470 733a2f2f 69312e73 6e646364 6e2e636f 6d2f6176 61746172 732d3030 30303032 39353838 33322d78 786d6f6a 612d6c61 7267652e 6a70673f 64363939 3538373c 2f617661 7461722d 75726c3e 0a20203c 2f757365 723e0a20 203c7573 65722d70 6c617962 61636b2d 636f756e 74207479 70653d22 696e7465 67657222 3e313c2f 75736572 2d706c61 79626163 6b2d636f 756e743e 0a20203c 75736572 2d666176 6f726974 65207479 70653d22 626f6f6c 65616e22 3e66616c 73653c2f 75736572 2d666176 6f726974 653e0a20 203c7065 726d616c 696e6b2d 75726c3e 68747470 3a2f2f73 6f756e64 636c6f75 642e636f 6d2f656c 6d657263 61742f6b 67746e6a 6d78622d 72696e67 6261636b 3c2f7065 726d616c 696e6b2d 75726c3e 0a20203c 61727477 6f726b2d 75726c3e 68747470 733a2f2f 69312e73 6e646364 6e2e636f 6d2f6172 74776f72 6b732d30 30303032 37333937 3138302d 72753433 61342d6c 61726765 2e6a7067 3f643639 39353837 3c2f6172 74776f72 6b2d7572 6c3e0a20 203c7761 7665666f 726d2d75 726c3e68 74747073 3a2f2f77 312e736e 6463646e 2e636f6d 2f71454e 66764d31 4b55594c 705f6d2e 706e673c 2f776176 65666f72 6d2d7572 6c3e0a20 203c7374 7265616d 2d75726c 3e687474 70733a2f 2f617069 2e736f75 6e64636c 6f75642e 636f6d2f 74726163 6b732f35 34323437 3030392f 73747265 616d3c2f 73747265 616d2d75 726c3e0a 20203c64 6f776e6c 6f61642d 75726c3e 68747470 733a2f2f 6170692e 736f756e 64636c6f 75642e63 6f6d2f74 7261636b 732f3534 32343730 30392f64 6f776e6c 6f61643c 2f646f77 6e6c6f61 642d7572 6c3e0a20 203c706c 61796261 636b2d63 6f756e74 20747970 653d2269 6e746567 6572223e 333c2f70 6c617962 61636b2d 636f756e 743e0a20 203c646f 776e6c6f 61642d63 6f756e74 20747970 653d2269 6e746567 6572223e 303c2f64 6f776e6c 6f61642d 636f756e 743e0a20 203c6661 766f7269 74696e67 732d636f 756e7420 74797065 3d22696e 74656765 72223e30 3c2f6661 766f7269 74696e67 732d636f 756e743e 0a20203c 636f6d6d 656e742d 636f756e 74207479 70653d22 696e7465 67657222 3e303c2f 636f6d6d 656e742d 636f756e 743e0a20 203c6174 74616368 6d656e74 732d7572 693e6874 7470733a 2f2f6170 692e736f 756e6463 6c6f7564 2e636f6d 2f747261 636b732f 35343234 37303039 2f617474 6163686d 656e7473 3c2f6174 74616368 6d656e74 732d7572 693e0a20 203c7365 63726574 2d746f6b 656e3e73 2d725375 34793c2f 73656372 65742d74 6f6b656e 3e0a2020 3c736563 7265742d 7572693e 68747470 733a2f2f 6170692e 736f756e 64636c6f 75642e63 6f6d2f74 7261636b 732f3534 32343730 30393f73 65637265 745f746f 6b656e3d 732d7253 7534793c 2f736563 7265742d 7572693e 0a20203c 646f776e 6c6f6164 732d7265 6d61696e 696e6720 74797065 3d22696e 74656765 72223e31 3030303c 2f646f77 6e6c6f61 64732d72 656d6169 6e696e67 3e0a3c2f 74726163 6b3e0a>
 
*/