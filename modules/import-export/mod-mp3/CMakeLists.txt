set( TARGET mod-mp3 )

set( SOURCES
      ExportMP3.cpp
      ExportMP3.h
      MP3.cpp
      MP3Prefs.cpp
)

set( LIBRARIES
   PRIVATE
      Audacity
      libmp3lame::libmp3lame
)

if ( USE_LIBID3TAG )
      list ( APPEND LIBRARIES PRIVATE libid3tag::libid3tag)
endif()

set (EXTRA_CLUSTER_NODES "${LIBRARIES}" PARENT_SCOPE)

audacity_module( ${TARGET} "${SOURCES}" "${LIBRARIES}" "" "" )
