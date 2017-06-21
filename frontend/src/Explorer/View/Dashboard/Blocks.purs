module Explorer.View.Dashboard.Blocks (dashBoardBlocksView) where

import Prelude hiding (id)

import Data.Array (length, null, slice)
import Data.Lens ((^.))
import Data.Maybe (Maybe(..))
import Network.RemoteData (RemoteData(..), isLoading, isNotAsked, withDefault)

import Pux.DOM.HTML (HTML) as P
import Pux.DOM.Events (onClick) as P

import Text.Smolder.HTML (div, p)
import Text.Smolder.HTML.Attributes (className, id)
import Text.Smolder.Markup (text, (#!), (!))

import Explorer.I18n.Lang (translate)
import Explorer.I18n.Lenses (cExpand, cOf, cLoading, dashboard, dbLastBlocks, common, dbExploreBlocks, cNoData) as I18nL
import Explorer.Lenses.State (dbViewBlockPagination, dbViewBlockPaginationEditable, dbViewBlocksExpanded, dbViewLoadingBlockPagination, dbViewMaxBlockPagination, lang, latestBlocks)
import Explorer.State (minPagination)
import Explorer.Types.Actions (Action(..))
import Explorer.Types.State (CBlockEntries, PageNumber(..), State)
import Explorer.View.Blocks (blockRow, blocksHeaderView, maxBlockRows, minBlockRows)
import Explorer.View.CSS (blocksBody, blocksBodyWrapper, blocksBodyCover, blocksBodyCoverLabel, blocksFooter, blocksWaiting, dashboardContainer, dashboardWrapper, dashBoardBlocksViewId) as CSS
import Explorer.View.Common (paginationView)
import Explorer.View.Dashboard.Lenses (dashboardBlocksExpanded, dashboardViewState)
import Explorer.View.Dashboard.Shared (headerView)
import Explorer.View.Dashboard.Types (HeaderLink(..), HeaderOptions(..))

dashBoardBlocksView :: State -> P.HTML Action
dashBoardBlocksView state =
    div ! className CSS.dashboardWrapper
        ! id CSS.dashBoardBlocksViewId
        $ div ! className CSS.dashboardContainer $ do
              headerView state headerOptions
              case state ^. latestBlocks of
                  NotAsked  -> emptyBlocksView ""
                  Loading -> if hasBlocks then blocksView else emptyBlocksView ""
                  Failure _ -> emptyBlocksView $ translate (I18nL.common <<< I18nL.cNoData) lang'
                  Success _ -> blocksView
      where
        headerOptions = HeaderOptions
            { headline: translate (I18nL.dashboard <<< I18nL.dbLastBlocks) lang'
            , link: Just $ HeaderLink { label: translate (I18nL.dashboard <<< I18nL.dbExploreBlocks) lang'
                                      , action: NoOp }
            }
        lang' = state ^. lang
        hasBlocks = not null $ withDefault [] $ state ^. latestBlocks
        remoteDataMaxPages = state ^. (dashboardViewState <<< dbViewMaxBlockPagination)
        blocksView =
            div do
                blocksHeaderView (withDefault [] $ state ^. latestBlocks) lang'
                div ! className CSS.blocksBodyWrapper $ do
                    div ! className CSS.blocksBody
                        $ map (blockRow state) (currentBlocks state)
                    div ! className $ CSS.blocksBodyCover
                              <>  if  isNotAsked remoteDataMaxPages ||
                                      isLoading remoteDataMaxPages ||
                                      state ^. (dashboardViewState <<< dbViewLoadingBlockPagination)
                                  then " show"
                                  else ""
                        $ p ! className CSS.blocksBodyCoverLabel
                            $ text (translate (I18nL.common <<< I18nL.cLoading) lang')
                div ! className CSS.blocksFooter
                    $ blocksFooterView state

emptyBlocksView :: String -> P.HTML Action
emptyBlocksView message =
    div ! className CSS.blocksWaiting
        $ text message

currentBlocks :: State -> CBlockEntries
currentBlocks state =
    if expanded
    then slice 0 maxBlockRows blocks
    else slice 0 minBlockRows blocks
    where
        blocks = withDefault [] $ state ^. latestBlocks
        expanded = state ^. dashboardBlocksExpanded

blocksFooterView :: State -> P.HTML Action
blocksFooterView state =
    if expanded then
        paginationView { label: translate (I18nL.common <<< I18nL.cOf) $ lang'
                        , currentPage: currentPageNumber
                        , minPage: PageNumber minPagination
                        , maxPage: withDefault (PageNumber minPagination) remoteDataMaxPages
                        , changePageAction: DashboardPaginateBlocks
                        , editable: state ^. (dashboardViewState <<< dbViewBlockPaginationEditable)
                        , editableAction: DashboardEditBlocksPageNumber
                        , invalidPageAction: DashboardInvalidBlocksPageNumber
                        , disabled: isNotAsked remoteDataMaxPages || isLoading remoteDataMaxPages ||
                                    state ^. (dashboardViewState <<< dbViewLoadingBlockPagination)
                        }
    else
        div ! className ("btn-expand" <> visibleBtnExpandClazz)
            #! onClick clickHandler
            $ text (translate (I18nL.common <<< I18nL.cExpand) lang')
    where
        lang' = state ^. lang
        remoteDataMaxPages = state ^. (dashboardViewState <<< dbViewMaxBlockPagination)
        blocks = withDefault [] $ state ^. latestBlocks
        expanded = state ^. (dashboardViewState <<< dbViewBlocksExpanded)
        currentPageNumber = state ^. (dashboardViewState <<< dbViewBlockPagination)
        expandable =  (length blocks > minBlockRows) ||
                      (currentPageNumber > PageNumber minPagination)
        clickHandler _ =
            if expandable
            then DashboardExpandBlocks true
            else NoOp
        visibleBtnExpandClazz = if expandable then "" else " disabled"
