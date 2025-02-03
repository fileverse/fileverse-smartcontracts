// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract FileverseComment is ReentrancyGuard, ERC2771Context {
    struct Comment {
        address author;
        string contentHash;
        uint256 timestamp;
        bool isResolved;
        bool isDeleted;
    }

    // Mapping from portal address => ddocId => array of comments
    mapping(address => mapping(string => Comment[])) private _comments;

    // Address of trusted forwarder
    address private immutable trustedForwarder;

    event CommentAdded(address indexed portal, string indexed ddocId, address indexed author, string contentHash, uint256 commentIndex);
    event CommentResolved(address indexed portal, string indexed ddocId, uint256 commentIndex);
    event CommentDeleted(address indexed portal, string indexed ddocId, uint256 commentIndex);

    /**
     * @notice Constructor for FileverseComment contract
     * @param _trustedForwarder - Instance of the trusted forwarder
     */
    constructor(address _trustedForwarder) ERC2771Context(_trustedForwarder) {
        require(_trustedForwarder != address(0), "FV211");
        trustedForwarder = _trustedForwarder;
    }

    /**
     * @notice Add a new comment for a portal's file
     * @param _portal - Address of the portal
     * @param _ddocId - ID of the file being commented on
     * @param _contentHash - Content hash of the comment
     */
    function addComment(
        address _portal,
        string calldata _ddocId,
        string calldata _contentHash
    ) external nonReentrant {
        require(_portal != address(0), "Invalid portal address");
        require(bytes(_ddocId).length > 0, "Invalid ddoc ID");
        require(bytes(_contentHash).length > 0, "Empty comment");

        address author = _msgSender();
        Comment memory newComment = Comment({
            author: author,
            contentHash: _contentHash,
            timestamp: block.timestamp,
            isResolved: false,
            isDeleted: false
        });

        uint256 commentIndex = _comments[_portal][_ddocId].length;
        _comments[_portal][_ddocId].push(newComment);
        emit CommentAdded(_portal, _ddocId, author, _contentHash, commentIndex);
    }

    /**
     * @notice Mark a comment as resolved
     * @param _portal - Address of the portal
     * @param _ddocId - ID of the file
     * @param _commentIndex - Index of the comment to resolve
     */
    function resolveComment(
        address _portal,
        string calldata _ddocId,
        uint256 _commentIndex
    ) external nonReentrant {
        require(_portal != address(0), "Invalid portal address");
        require(bytes(_ddocId).length > 0, "Invalid ddoc ID");
        require(_commentIndex < _comments[_portal][_ddocId].length, "Invalid comment index");
        
        address caller = _msgSender();
        FileversePortal portal = FileversePortal(_portal);
        
        // Allow both portal owner and comment author to resolve
        require(
            portal.owner() == caller || 
            _comments[_portal][_ddocId][_commentIndex].author == caller, 
            "Only portal owner or comment author can resolve"
        );

        require(!_comments[_portal][_ddocId][_commentIndex].isResolved, "Comment already resolved");
        require(!_comments[_portal][_ddocId][_commentIndex].isDeleted, "Comment is deleted");
        
        _comments[_portal][_ddocId][_commentIndex].isResolved = true;
        emit CommentResolved(_portal, _ddocId, _commentIndex);
    }

    /**
     * @notice Delete a comment
     * @param _portal - Address of the portal
     * @param _ddocId - ID of the file
     * @param _commentIndex - Index of the comment to delete
     */
    function deleteComment(
        address _portal,
        string calldata _ddocId,
        uint256 _commentIndex
    ) external nonReentrant {
        require(_portal != address(0), "Invalid portal address");
        require(bytes(_ddocId).length > 0, "Invalid ddoc ID");
        require(_commentIndex < _comments[_portal][_ddocId].length, "Invalid comment index");
        
        address caller = _msgSender();
        FileversePortal portal = FileversePortal(_portal);

        // Allow both portal owner and comment author to delete
        require(
            portal.owner() == caller || 
            _comments[_portal][_ddocId][_commentIndex].author == caller,
            "Only portal owner or comment author can delete"
        );

        require(!_comments[_portal][_ddocId][_commentIndex].isDeleted, "Comment already deleted");
        
        _comments[_portal][_ddocId][_commentIndex].isDeleted = true;
        emit CommentDeleted(_portal, _ddocId, _commentIndex);
    }

    /**
     * @notice Get paginated comments for a portal's file
     * @param _portal - Address of the portal
     * @param _ddocId - ID of the file
     * @param _resultsPerPage - Number of results per page
     * @param _page - Page number (1-based)
     * @return comments - Array of comments for the requested page
     */
    function getComments(
        address _portal, 
        string calldata _ddocId,
        uint256 _resultsPerPage,
        uint256 _page
    ) external view returns (Comment[] memory) {
        uint256 len = _comments[_portal][_ddocId].length;
        uint256 startIndex = _resultsPerPage * _page - _resultsPerPage;
        uint256 endIndex = Math.min(_resultsPerPage * _page, len);
        
        if (startIndex > len) {
            revert("Page out of bounds");
        }

        Comment[] memory results = new Comment[](endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; ++i) {
            results[i - startIndex] = _comments[_portal][_ddocId][i];
        }
        return results;
    }

    /**
     * @notice Get comment count for a portal's file
     * @param _portal - Address of the portal
     * @param _ddocId - ID of the file
     * @return count - Number of comments
     */
    function getCommentCount(address _portal, string calldata _ddocId)
        external
        view
        returns (uint256)
    {
        return _comments[_portal][_ddocId].length;
    }
}
