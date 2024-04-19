#ifndef AU_PROJECT_PROJECTACTIONSCONTROLLER_H
#define AU_PROJECT_PROJECTACTIONSCONTROLLER_H

#include "iprojectfilescontroller.h"

#include "actions/actionable.h"
#include "modularity/ioc.h"
#include "iinteractive.h"
#include "actions/iactionsdispatcher.h"
#include "context/iglobalcontext.h"
#include "global/iinteractive.h"
#include "global/io/ifilesystem.h"
#include "../iprojectconfiguration.h"
#include "irecentfilescontroller.h"
#include "iprojectautosaver.h"

#include "../iaudacityproject.h"

namespace au::project {
class ProjectActionsController : public IProjectFilesController, public muse::actions::Actionable
{
    muse::Inject<muse::actions::IActionsDispatcher> dispatcher;
    muse::Inject<au::context::IGlobalContext> globalContext;
    muse::Inject<muse::IInteractive> interactive;
    muse::Inject<IProjectConfiguration> configuration;
    muse::Inject<muse::io::IFileSystem> fileSystem;
    INJECT(IRecentFilesController, recentFilesController)
    INJECT(IProjectAutoSaver, projectAutoSaver)

public:
    ProjectActionsController() = default;

    void init();
    muse::Ret openProject(const ProjectFile& file) override;
    bool isUrlSupported(const QUrl& url) const override;
    bool isFileSupported(const muse::io::path_t& path) const override;
    bool closeOpenedProject(bool quitApp = false) override;
    bool saveProject(const muse::io::path_t& path = muse::io::path_t()) override;
    bool saveProjectLocally(const muse::io::path_t& filePath = muse::io::path_t(), SaveMode saveMode = SaveMode::Save) override;

    const ProjectBeingDownloaded& projectBeingDownloaded() const override;
    muse::async::Notification projectBeingDownloadedChanged() const override;

    bool isProjectOpened(const muse::io::path_t& projectPath) const;

private:
    project::IAudacityProjectPtr currentProject() const;

    void newProject();
    void openProject(const muse::actions::ActionData& args);
    muse::Ret openProject(const muse::io::path_t& givenPath, const muse::String& displayNameOverride = muse::String());
    muse::Ret doOpenProject(const muse::io::path_t& filePath);
    //! TODO AU4
    // muse::Ret openAudacityUrl(const QUrl& url);
    muse::RetVal<IAudacityProjectPtr> loadProject(const muse::io::path_t& filePath);
    muse::io::path_t selectOpeningFile();
    muse::Ret canSaveProject() const;
    bool saveProject(SaveMode saveMode, SaveLocationType saveLocationType = SaveLocationType::Undefined, bool force = false);
    bool saveProjectAt(const SaveLocation& saveLocation, SaveMode saveMode = SaveMode::Save, bool force = false);

    RecentFile makeRecentFile(IAudacityProjectPtr project);
    void clearRecentProjects();

    muse::Ret openPageIfNeed(muse::Uri pageUri);

    bool m_isProjectSaving = false;
    bool m_isProjectProcessing = false;
    ProjectBeingDownloaded m_projectBeingDownloaded;
    muse::async::Notification m_projectBeingDownloadedChanged;
};
}

#endif // AU_PROJECT_PROJECTACTIONSCONTROLLER_H
