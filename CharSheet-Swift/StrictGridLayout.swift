//
//  PWStrictGridLayout.m
//  CharSheet
//
//  Created by Patrick Wallace on 16/01/2013.
//
//

import UIKit


//static CGRect frameFromAttributes(UICollectionViewLayoutAttributes *attributes);
//static CGRect rectForNewRow(CGRect oldFrame, CGSize cellSize, CGSize cellSpacing, CGSize contentInsets);
//static CGRect rectForNewColumn(CGRect oldFrame, CGSize cellSize, CGSize cellSpacing);
//static CGSize getContentSize(NSUInteger itemCount, NSUInteger columns, CGSize contentInsets, NSArray *collectionItemAttributes);

class StrictGridLayout : UICollectionViewLayout {

    private var itemCount = 0
    private var contentSize = CGSizeZero
    private var collectionItemAttributes: [UICollectionViewLayoutAttributes] = []
    
    // Number of columns.
    var columns = 2
    
    // Size of each cell.
    var cellSize = CGSizeMake(350, 100)
    
    // Spacing between cells in X and Y dimensions.
    var cellSpacing = CGSizeMake(  0,  20)
    
    // Insets of all content (e.g. space between top border and 1st cell, bottom border and last cell etc.)
    var contentInsets = CGSizeMake( 0,  20)
    
//-(void)setDefaults;
//-(UICollectionViewLayoutAttributes*)attributesForIndex:(NSUInteger)i withFrame:(CGRect)itemFrame;

    func newRowForColumn(currentColumn: Int , maxColumns: Int ) -> Bool {
        return currentColumn >= maxColumns
    }

//    func setDefaults() {
//        self.columns = 2
//        self.cellSize     = CGSizeMake(350, 100)
//        self.cellSpacing  = CGSizeMake(  0,  20)
//        self.contentInsets = CGSizeMake( 0,  20)
//    }
    
    func attributesForIndex(i: Int, withFrame itemFrame: CGRect) -> UICollectionViewLayoutAttributes {
        let indexPath = NSIndexPath(forItem: i, inSection:0)
        let attributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
        attributes.frame = itemFrame;
        return attributes;
    }
    

    override func prepareLayout() {
        // Init is sometimes not called, so check for this and set some defaults if so.
        assert(columns > 0, "Columns not set correctly. init() has been bypassed.")
//        if self.columns == 0 {
//            self.setDefaults()
//        }
        if let collectionView = self.collectionView {
            assert((cellSize.width > 0 && cellSize.height > 0), "Cell size [\(cellSize.width), \(cellSize.height)] must not be zero in either dimension");
            assert(collectionView.numberOfSections() == 1, "The StrictGridLayout only handles single section collection views")
            itemCount = collectionView.numberOfItemsInSection(0)
            collectionItemAttributes = [UICollectionViewLayoutAttributes]()
            
            var itemFrame = CGRectMake(contentInsets.width, contentInsets.height, cellSize.width, cellSize.height)
            var itemInColumn = 0;
            for var i = 0; i < itemCount; ++i {
                collectionItemAttributes.append(attributesForIndex(i, withFrame:itemFrame))
                
                itemInColumn++
                itemFrame = newRowForColumn(itemInColumn, maxColumns: self.columns)
                    ? rectForNewRow   (itemFrame, cellSize: cellSize, cellSpacing: cellSpacing, contentInsets: contentInsets)
                    : rectForNewColumn(itemFrame, cellSize: cellSize, cellSpacing: cellSpacing)
                if newRowForColumn(itemInColumn, maxColumns: self.columns) {
                    itemInColumn = 0;
                }
            }
            
            contentSize = getContentSize(itemCount, columns: columns, contentInsets: contentInsets, collectionItemAttributes: collectionItemAttributes)
        }
    }

    override func collectionViewContentSize() -> CGSize {
        //assert(collectionItemAttributes != nil, "collectionItemAttributes is missing. prepareLayout was not called properly")
        return contentSize
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes] {
        //assert(collectionItemAttributes != nil, "collectionItemAttributes is missing. prepareLayout was not called properly")
        return collectionItemAttributes.filter{ object in CGRectIntersectsRect(rect, object.frame) }
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes {
        //assert(collectionItemAttributes != nil, "collectionItemAttributes is missing. prepareLayout was not called properly")
        return collectionItemAttributes[indexPath.item]
    }
    
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool { return false }
    
    
    
    func rectForNewRow( oldFrame: CGRect,  cellSize: CGSize,  cellSpacing: CGSize,  contentInsets: CGSize) -> CGRect
    {
        return CGRectMake(contentInsets.width, oldFrame.origin.y + cellSize.height + cellSpacing.height, oldFrame.size.width, oldFrame.size.height)
    }
    
    func rectForNewColumn(oldFrame: CGRect, cellSize: CGSize, cellSpacing: CGSize) -> CGRect
    {
        return CGRectMake(oldFrame.origin.x + cellSize.width + cellSpacing.width, oldFrame.origin.y, oldFrame.size.width, oldFrame.size.height);
    }

    func getContentSize(itemCount: Int , columns: Int , contentInsets: CGSize , collectionItemAttributes: NSArray) -> CGSize
    {
        assert(columns > 0);
        if itemCount == 0 { return CGSizeZero }
        
        // Get one of the rightmost cells and use its bounds to get the width of the content as a whole.
        // Get the last cell and use it's bounds to get the height.
        let rightmostItemIndex = min(itemCount - 1, columns - 1)
        let bottomItemIndex    = itemCount - 1
        
        let rightmostFrame = collectionItemAttributes[rightmostItemIndex].frame
        let bottomFrame    = collectionItemAttributes[bottomItemIndex].frame
        
        return CGSizeMake(CGRectGetMaxX(rightmostFrame) + (contentInsets.width  * 2), CGRectGetMaxY(bottomFrame) + (contentInsets.height * 2))
    }
}
