//
//  PWStrictGridLayout.m
//  CharSheet
//
//  Created by Patrick Wallace on 16/01/2013.
//
//

import UIKit

/// Layout manager which arranges components in a grid with a pre-defined cell size.
/// The values in the grid are hard-coded as are the number of columns (2). 
/// The number of rows is allowed to vary.
///
/// This is designed to hold a collection of SkillCell views, which all have a fixed size. It could be generalised by setting the number of columns,
/// the cell size and the spacing as parameters which can be set in Interface Builder.

class StrictGridLayout : UICollectionViewLayout
{
	// MARK: Private Data

    private var itemCount = 0
    private var contentSize = CGSizeZero
    private var collectionItemAttributes: [UICollectionViewLayoutAttributes] = []

	// MARK: Constants.

	/// Number of columns.
    let columns = 2
    
	/// Size of each cell.
    let cellSize = CGSizeMake(350, 100)
    
	/// Spacing between cells in X and Y dimensions.
    let cellSpacing = CGSize(width: 0,  height: 20)
    
	/// Insets of all content (e.g. space between top border and 1st cell, bottom border and last cell etc.)
    let contentInsets = CGSize(width: 0,  height: 20)

	// MARK: Overrides

    override func prepareLayout()
	{
		func newRowForColumn(currentColumn: Int , maxColumns: Int ) -> Bool
		{
			return currentColumn >= maxColumns
		}

		func attributesForIndex(i: Int, withFrame itemFrame: CGRect) -> UICollectionViewLayoutAttributes
		{
			let indexPath = NSIndexPath(forItem: i, inSection:0)
			let attributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
			attributes.frame = itemFrame
			return attributes
		}

		func rectForNewRow(oldFrame: CGRect,  cellSize: CGSize,  cellSpacing: CGSize,  contentInsets: CGSize) -> CGRect
		{
			return CGRectMake(contentInsets.width, oldFrame.origin.y + cellSize.height + cellSpacing.height, oldFrame.size.width, oldFrame.size.height)
		}

		func rectForNewColumn(oldFrame: CGRect, cellSize: CGSize, cellSpacing: CGSize) -> CGRect
		{
			return CGRectMake(oldFrame.origin.x + cellSize.width + cellSpacing.width, oldFrame.origin.y, oldFrame.size.width, oldFrame.size.height)
		}

		func getContentSize(itemCount: Int, columns: Int, contentInsets: CGSize, collectionItemAttributes: NSArray) -> CGSize
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




		// Init is sometimes not called, so check for this and set some defaults if so.
        assert(columns > 0, "Columns not set correctly. init() has been bypassed.")
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

    override func collectionViewContentSize() -> CGSize
	{
        return contentSize
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]
	{
        return collectionItemAttributes.filter { object in CGRectIntersectsRect(rect, object.frame) }
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes
	{
        return collectionItemAttributes[indexPath.item]
    }
    
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool
	{
		return false
	}
}
