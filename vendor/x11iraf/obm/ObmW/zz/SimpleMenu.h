/*
 * $XConsortium: SimpleMenu.h,v 1.17 89/12/11 15:01:55 kit Exp $
 *
 * Copyright 1989 Massachusetts Institute of Technology
 *
 * Permission to use, copy, modify, distribute, and sell this software and its
 * documentation for any purpose is hereby granted without fee, provided that
 * the above copyright notice appear in all copies and that both that
 * copyright notice and this permission notice appear in supporting
 * documentation, and that the name of M.I.T. not be used in advertising or
 * publicity pertaining to distribution of the software without specific,
 * written prior permission.  M.I.T. makes no representations about the
 * suitability of this software for any purpose.  It is provided "as is"
 * without express or implied warranty.
 *
 * M.I.T. DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING ALL
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN NO EVENT SHALL M.I.T.
 * BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION
 * OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN 
 * CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 * Author:  Chris D. Peterson, MIT X Consortium
 */

/*
 * SimpleMenu.h - Public Header file for SimpleMenu widget.
 *
 * This is the public header file for the Athena SimpleMenu widget.
 * It is intended to provide one pane pulldown and popup menus within
 * the framework of the X Toolkit.  As the name implies it is a first and
 * by no means complete implementation of menu code. It does not attempt to
 * fill the needs of all applications, but does allow a resource oriented
 * interface to menus.
 *
 * Date:    April 3, 1989
 *
 * By:      Chris D. Peterson
 *          MIT X Consortium 
 *          kit@expo.lcs.mit.edu
 */

#ifndef _SimpleMenu_h
#define _SimpleMenu_h

#include <X11/Shell.h>
#include <X11/Xmu/Converters.h>

/****************************************************************
 *
 * SimpleMenu widget
 *
 ****************************************************************/

/* SimpleMenu Resources:

 Name		     Class		RepType		Default Value
 ----		     -----		-------		-------------
 background	     Background		Pixel		XtDefaultBackground
 backgroundPixmap    BackgroundPixmap	Pixmap          None
 borderColor	     BorderColor	Pixel		XtDefaultForeground
 borderPixmap	     BorderPixmap	Pixmap		None
 borderWidth	     BorderWidth	Dimension	1
 bottomMargin        VerticalMargins    Dimension       VerticalSpace
 columnWidth         ColumnWidth        Dimension       Width of widest text
 cursor              Cursor             Cursor          None
 destroyCallback     Callback		Pointer		NULL
 height		     Height		Dimension	0
 label               Label              String          NULL (No label)
 labelClass          LabelClass         Pointer         smeBSBObjectClass
 mappedWhenManaged   MappedWhenManaged	Boolean		True
 rowHeight           RowHeight          Dimension       Height of Font
 sensitive	     Sensitive		Boolean		True
 topMargin           VerticalMargins    Dimension       VerticalSpace
 width		     Width		Dimension	0
 x		     Position		Position	0
 y		     Position		Position	0

*/

typedef struct _SimpleMenuClassRec*	SimpleMenuWidgetClass;
typedef struct _SimpleMenuRec*		SimpleMenuWidget;

extern WidgetClass simpleMenuWidgetClass;

#define XtNcursor "cursor"
#define XtNbottomMargin "bottomMargin"
#define XtNcolumnWidth "columnWidth"
#define XtNlabelClass "labelClass"
#define XtNmenuOnScreen "menuOnScreen"
#define XtNpopupOnEntry "popupOnEntry"
#define XtNrowHeight "rowHeight"
#define XtNtopMargin "topMargin"

#define XtCColumnWidth "ColumnWidth"
#define XtCLabelClass "LabelClass"
#define XtCMenuOnScreen "MenuOnScreen"
#define XtCPopupOnEntry "PopupOnEntry"
#define XtCRowHeight "RowHeight"
#define XtCVerticalMargins "VerticalMargins"

/* New fields */
#define XtNshadowWidth "shadowWidth"
#define XtCShadowWidth "ShadowWidth"
#define XtNbsbShadowWidth "bsbShadowWidth"
#define XtCBsbShadowWidth "BsbShadowWidth"
#define XtNtopShadowPixel "topShadowPixel"
#define XtCTopShadowPixel "TopShadowPixel"
#define XtNbottomShadowPixel "bottomShadowPixel"
#define XtCBottomShadowPixel "BottomShadowPixel"
#define XtNtopShadowContrast "topShadowContrast"
#define XtCTopShadowContrast "TopShadowContrast"
#define XtNbottomShadowContrast "bottomShadowContrast"
#define XtCBottomShadowContrast "BottomShadowContrast"
#define XtNbeNiceToColormap "beNiceToColormap"
#define XtCBeNiceToColormap "BeNiceToColormap"
#define XtNtopShadowPixmap "topShadowPixmap"
#define XtCTopShadowPixmap "TopShadowPixmap"
#define XtNbottomShadowPixmap "bottomShadowPixmap"
#define XtCBottomShadowPixmap "BottomShadowPixmap"
#define XtNuserData "userData"
#define XtCUserData "UserData"
#define XtNframeType "frameType"
#define XtCFrameType "FrameType"
#define XtRFrameType "FrameType"

/************************************************************
 *
 * Public Functions.
 *
 ************************************************************/

/*	Function Name: XawSimpleMenuAddGlobalActions
 *	Description: adds the global actions to the simple menu widget.
 *	Arguments: app_con - the appcontext.
 *	Returns: none.
 */

void 
XawSimpleMenuAddGlobalActions(/* app_con */);
/*
XtAppContext app_con;
*/
 
/*	Function Name: XawSimpleMenuGetActiveEntry
 *	Description: Gets the currently active (set) entry.
 *	Arguments: w - the smw widget.
 *	Returns: the currently set entry or NULL if none is set.
 */

Widget
XawSimpleMenuGetActiveEntry( /* w */);
/*
Widget w;
*/

/*	Function Name: XawSimpleMenuClearActiveEntry
 *	Description: Unsets the currently active (set) entry.
 *	Arguments: w - the smw widget.
 *	Returns: none.
 */

void
XawSimpleMenuClearActiveEntry(/* w */);
/*
Widget w;
*/

#endif /* _SimpleMenu_h */