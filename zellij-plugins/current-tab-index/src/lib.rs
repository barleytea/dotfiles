use std::collections::BTreeMap;

use zellij_tile::prelude::*;

#[derive(Default)]
struct CurrentTabIndexPlugin {
    tabs: Vec<TabInfo>,
}

impl CurrentTabIndexPlugin {
    fn active_tab_index(&self) -> Option<usize> {
        self.tabs.iter().find(|tab| tab.active).map(|tab| tab.position)
    }
}

impl ZellijPlugin for CurrentTabIndexPlugin {
    fn load(&mut self, _configuration: BTreeMap<String, String>) {
        subscribe(&[EventType::TabUpdate]);
    }

    fn update(&mut self, event: Event) -> bool {
        if let Event::TabUpdate(tabs) = event {
            self.tabs = tabs;
        }
        false
    }

    fn pipe(&mut self, pipe_message: PipeMessage) -> bool {
        if pipe_message.name != "current_tab_index" {
            return false;
        }

        if let PipeSource::Cli(pipe_id) = pipe_message.source {
            let output = self
                .active_tab_index()
                .map(|index| index.to_string())
                .unwrap_or_default();
            cli_pipe_output(&pipe_id, &output);
        }

        false
    }
}

register_plugin!(CurrentTabIndexPlugin);
