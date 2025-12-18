-- Sinergista Database Structure
-- Generated based on current Supabase project schema

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- -----------------------------------------------------------------------------
-- Tables
-- -----------------------------------------------------------------------------

-- profiles
CREATE TABLE public.profiles (
    id uuid NOT NULL REFERENCES auth.users(id),
    username text UNIQUE,
    full_name text,
    avatar_url text,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
    role text DEFAULT 'user'::text,
    PRIMARY KEY (id)
);

-- modules
CREATE TABLE public.modules (
    id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
    user_id uuid NOT NULL REFERENCES public.profiles(id),
    title text NOT NULL,
    description text,
    due_date timestamp with time zone,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
    image_url text,
    is_public boolean DEFAULT false,
    member_count integer DEFAULT 1,
    category text,
    status text DEFAULT 'active'::text,
    all_day boolean DEFAULT false,
    start_time time without time zone,
    end_time time without time zone,
    banner_url text,
    PRIMARY KEY (id)
);

-- tasks
CREATE TABLE public.tasks (
    id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
    user_id uuid NOT NULL REFERENCES public.profiles(id),
    module_id uuid REFERENCES public.modules(id),
    title text NOT NULL,
    priority text DEFAULT 'Sedang'::text,
    is_completed boolean DEFAULT false,
    due_date timestamp with time zone,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
    file_link text,
    category text,
    notes text,
    PRIMARY KEY (id)
);

-- focus_sessions
CREATE TABLE public.focus_sessions (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES public.profiles(id),
    module_id uuid,
    start_time timestamp with time zone NOT NULL,
    end_time timestamp with time zone,
    duration_minutes integer,
    status text NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    PRIMARY KEY (id)
);

-- kanban_tasks
CREATE TABLE public.kanban_tasks (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    module_id uuid REFERENCES public.modules(id),
    title text NOT NULL,
    status text NOT NULL,
    "position" integer NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    description text,
    assignee_id uuid REFERENCES public.profiles(id),
    due_date timestamp with time zone,
    priority text DEFAULT 'medium'::text,
    labels jsonb DEFAULT '[]'::jsonb,
    attachments jsonb DEFAULT '[]'::jsonb,
    comments jsonb DEFAULT '[]'::jsonb,
    PRIMARY KEY (id)
);

-- achievements
CREATE TABLE public.achievements (
    id uuid NOT NULL DEFAULT uuid_generate_v4(),
    title text NOT NULL,
    description text NOT NULL,
    icon_name text,
    criteria jsonb,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
    PRIMARY KEY (id)
);

-- user_achievements
CREATE TABLE public.user_achievements (
    id uuid NOT NULL DEFAULT uuid_generate_v4(),
    user_id uuid NOT NULL REFERENCES public.profiles(id),
    achievement_id uuid NOT NULL REFERENCES public.achievements(id),
    unlocked_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
    PRIMARY KEY (id)
);

-- budgets
CREATE TABLE public.budgets (
    id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
    user_id uuid NOT NULL REFERENCES public.profiles(id),
    category text NOT NULL,
    amount numeric NOT NULL,
    description text, -- Corrected from details
    date timestamp with time zone DEFAULT timezone('utc'::text, now()),
    type text NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
    PRIMARY KEY (id)
);

-- banners
CREATE TABLE public.banners (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    image_url text NOT NULL,
    target_url text,
    caption text,
    active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    PRIMARY KEY (id)
);

-- module_members
CREATE TABLE public.module_members (
    id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
    module_id uuid REFERENCES public.modules(id),
    user_id uuid REFERENCES public.profiles(id),
    role text DEFAULT 'member'::text,
    joined_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
    PRIMARY KEY (id)
);

-- assessment_history
CREATE TABLE public.assessment_history (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id),
    title text NOT NULL,
    type text NOT NULL,
    score numeric NOT NULL,
    total_questions integer NOT NULL,
    correct_answers integer NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    details jsonb,
    PRIMARY KEY (id)
);

-- connections
CREATE TABLE public.connections (
    id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
    requester_id uuid NOT NULL REFERENCES public.profiles(id),
    receiver_id uuid NOT NULL REFERENCES public.profiles(id),
    status text DEFAULT 'pending'::text,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
    PRIMARY KEY (id)
);

-- journals
CREATE TABLE public.journals (
    id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
    user_id uuid NOT NULL REFERENCES public.profiles(id),
    title text NOT NULL,
    content text,
    mood text,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
    PRIMARY KEY (id)
);

-- notes
CREATE TABLE public.notes (
    id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
    user_id uuid NOT NULL REFERENCES public.profiles(id),
    title text NOT NULL,
    content text,
    is_pinned boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
    tags text[] DEFAULT '{}'::text[],
    PRIMARY KEY (id)
);

-- notifications
CREATE TABLE public.notifications (
    id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
    user_id uuid NOT NULL REFERENCES public.profiles(id),
    title text NOT NULL,
    message text NOT NULL,
    type text NOT NULL,
    is_read boolean DEFAULT false,
    data jsonb,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
    PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Row Level Security (RLS) Policies
-- -----------------------------------------------------------------------------

-- profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public profiles are viewable by everyone." ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can insert their own profile." ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile." ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- modules
ALTER TABLE public.modules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own modules." ON public.modules FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own modules." ON public.modules FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own modules." ON public.modules FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own modules." ON public.modules FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Modules Select Policy" ON public.modules FOR SELECT USING (
    (auth.uid() = user_id) OR 
    (EXISTS ( 
        SELECT 1 FROM module_members 
        WHERE (module_members.module_id = modules.id) 
        AND (module_members.user_id = auth.uid())
    ))
);

CREATE POLICY "Modules Update Policy" ON public.modules FOR UPDATE USING (
    (auth.uid() = user_id) OR 
    (EXISTS ( 
        SELECT 1 FROM module_members 
        WHERE (module_members.module_id = modules.id) 
        AND (module_members.user_id = auth.uid()) 
        AND (module_members.role = 'editor'::module_role) -- Note: check enum existence
    ))
);

-- tasks
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own tasks." ON public.tasks FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own tasks." ON public.tasks FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own tasks." ON public.tasks FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own tasks." ON public.tasks FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Tasks General Policy" ON public.tasks FOR ALL USING (
    (auth.uid() = user_id) OR 
    (EXISTS ( 
        SELECT 1 FROM modules m
        LEFT JOIN module_members mm ON (m.id = mm.module_id)
        WHERE (m.id = tasks.module_id) 
        AND ((m.user_id = auth.uid()) OR (mm.user_id = auth.uid()))
    ))
);

-- focus_sessions
ALTER TABLE public.focus_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own focus sessions." ON public.focus_sessions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own focus sessions." ON public.focus_sessions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own focus sessions." ON public.focus_sessions FOR UPDATE USING (auth.uid() = user_id);

-- kanban_tasks
ALTER TABLE public.kanban_tasks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view kanban tasks of modules they belong to" ON public.kanban_tasks FOR SELECT USING (
    (auth.uid() IN (SELECT modules.user_id FROM modules WHERE modules.id = kanban_tasks.module_id)) OR 
    (auth.uid() IN (SELECT module_members.user_id FROM module_members WHERE module_members.module_id = kanban_tasks.module_id))
);

CREATE POLICY "Users can insert kanban tasks to modules they belong to" ON public.kanban_tasks FOR INSERT WITH CHECK (
    (auth.uid() IN (SELECT modules.user_id FROM modules WHERE modules.id = kanban_tasks.module_id)) OR 
    (auth.uid() IN (SELECT module_members.user_id FROM module_members WHERE module_members.module_id = kanban_tasks.module_id))
);

CREATE POLICY "Users can update kanban tasks of modules they belong to" ON public.kanban_tasks FOR UPDATE USING (
    (auth.uid() IN (SELECT modules.user_id FROM modules WHERE modules.id = kanban_tasks.module_id)) OR 
    (auth.uid() IN (SELECT module_members.user_id FROM module_members WHERE module_members.module_id = kanban_tasks.module_id))
);

CREATE POLICY "Users can delete kanban tasks of modules they belong to" ON public.kanban_tasks FOR DELETE USING (
    (auth.uid() IN (SELECT modules.user_id FROM modules WHERE modules.id = kanban_tasks.module_id)) OR 
    (auth.uid() IN (SELECT module_members.user_id FROM module_members WHERE module_members.module_id = kanban_tasks.module_id))
);

-- banners
ALTER TABLE public.banners ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view active banners" ON public.banners FOR SELECT USING (true);
CREATE POLICY "Admins can manage banners" ON public.banners FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin'::text)
);

-- assessment_history
ALTER TABLE public.assessment_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert their own history" ON public.assessment_history FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can view their own history" ON public.assessment_history FOR SELECT USING (auth.uid() = user_id);

-- budgets
ALTER TABLE public.budgets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own budgets" ON public.budgets FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own budgets" ON public.budgets FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own budgets" ON public.budgets FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own budgets" ON public.budgets FOR DELETE USING (auth.uid() = user_id);

-- notes
ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own notes" ON public.notes FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own notes" ON public.notes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own notes" ON public.notes FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own notes" ON public.notes FOR DELETE USING (auth.uid() = user_id);

-- journals
ALTER TABLE public.journals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own journals" ON public.journals FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own journals" ON public.journals FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own journals" ON public.journals FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own journals" ON public.journals FOR DELETE USING (auth.uid() = user_id);

-- notifications
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own notifications" ON public.notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own notifications" ON public.notifications FOR UPDATE USING (auth.uid() = user_id); -- Mark as read

-- connections
ALTER TABLE public.connections ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own connections" ON public.connections FOR SELECT USING (auth.uid() = requester_id OR auth.uid() = receiver_id);

-- achievements
ALTER TABLE public.achievements ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Achievements are viewable by everyone." ON public.achievements FOR SELECT USING (true);

-- user_achievements
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own unlocked achievements." ON public.user_achievements FOR SELECT USING (auth.uid() = user_id);
