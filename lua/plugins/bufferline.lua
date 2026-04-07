return {
	"akinsho/bufferline.nvim",

	opts = {
		options = {
			always_show_bufferline = true,
			buffer_close_icon = "󰅖",
			modified_icon = "● ",
			close_icon = " ",
			left_trunc_marker = " ",
			right_trunc_marker = " ",
			diagnostics = "nvim_lsp",
			diagnostics_update_on_event = true, -- use nvim's diagnostic handler
			diagnostics_indicator = function(_, _, diagnostics_dict, _)
				local s = " "
				for e, n in pairs(diagnostics_dict) do
					local sym = e == "error" and " " or (e == "warning" and " " or " ")
					s = s .. n .. sym
				end
				return s
			end,
			color_icons = true,
			get_element_icon = function(element)
				-- element consists of {filetype: string, path: string, extension: string, directory: string}
				-- This can be used to change how bufferline fetches the icon
				-- for an element e.g. a buffer or a tab.
				-- e.g.
				local icon, hl = require("mini.icons").get("filetype", element.filetype)
				return icon, hl
			end,
			show_buffer_icons = true,
			show_close_icon = true,
			show_tab_indicators = true,
			show_duplicate_prefix = true,
			duplicates_across_groups = true,
			numbers = function(opts)
				return string.format("%s·%s", opts.raise(opts.id), opts.lower(opts.ordinal))
			end,
		},
	},
}
