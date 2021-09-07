# GOGger-Wishlist
GOGger Wishlist is a program to keep tabs on game entries on your online GOG Wishlist.

It has been developed due to current limitations of the online GOG Wishlist, and to assist with purchasing decisions.

![GOGger Wishlist](https://github.com/Twombs/GOGger-Wishlist/blob/main/GOGger%20Wishlist.png?raw=true)

GOGger Wishlist is an adaption and improvement to my much older GetGOG Wishlist program, which had stopped working.

For games added to GOGger Wishlist, a few records are kept, and in some cases immediately displayed in columns and fields. This includes initial 'Start' price, subsequent price changes from checking, Game ID and game URL. Current price is displayed in the 'Last' price column. Lowest ever retrieved price is displayed in the 'Low' column, and highest in the 'High' column. Previous price is displayed in the 'Prior' column. Price checking requires a web connection, as does one optional ADD option. Titles and prices etc can also be added or checked via saved web pages. The date added and last checked are also recorded, plus a Log.txt file is also added to during CHECK PRICE, for any changed prices.

One optional ADD feature of the program, will probably require that the user's online GOG Wishlist be set to visible for 'Everyone' in account settings.

Game titles are displayed in the order added to the list, but all columns, except the URL one, can be sorted by clicking on the column header. NOTE - Alas, for some reason when sorted, that Listview feature removes trailing zeroes (i.e. '1.50' becomes '1.5' and '1.0' becomes '1' etc). This is not due to my coding, and does not effect stored records usually. On a reload or program restart, all is displayed as should be.

One of the UPDATE options can work with my GOGcli GUI program, to remove recent purchases from the Wishlist.

Enjoy!
